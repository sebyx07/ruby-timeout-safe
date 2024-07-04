#include "ruby.h"
#include <pthread.h>
#include <unistd.h>
#include <time.h>
#include <signal.h>
#include <errno.h>

/* Mutex and condition variable for thread synchronization */
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cond = PTHREAD_COND_INITIALIZER;

/* Mutex for protecting global_timeout_data */
static pthread_mutex_t global_data_mutex = PTHREAD_MUTEX_INITIALIZER;

/**
 * @brief Structure to hold timeout-related data
 */
struct timeout_data {
    time_t timeout;                 /**< Timeout duration in seconds */
    volatile int timeout_occurred;  /**< Flag indicating if timeout occurred */
    volatile int block_finished;    /**< Flag indicating if the Ruby block finished execution */
    volatile int signal_received;   /**< Flag indicating if a signal was received */
    pthread_t main_thread;          /**< Thread ID of the main thread */
};

/* Global pointer to the current timeout data (used by signal handler) */
static struct timeout_data *global_timeout_data = NULL;

/* Timeout::Error constant */
static VALUE rb_eTimeoutError;

/**
 * @brief Signal handler for SIGTERM and SIGINT.
 *
 * Sets the signal_received flag if global_timeout_data is available.
 *
 * @param signum The signal number (SIGTERM or SIGINT)
 */
static void signal_handler(int signum) {
    pthread_mutex_lock(&global_data_mutex);
    if (global_timeout_data) {
        __atomic_store_n(&global_timeout_data->signal_received, 1, __ATOMIC_SEQ_CST);
    }
    pthread_mutex_unlock(&global_data_mutex);
}

/**
 * @brief Timeout thread function.
 *
 * Waits for the specified timeout or until the block finishes execution.
 *
 * @param arg A pointer to the timeout_data structure
 * @return NULL
 */
static void* timeout_function(void *arg) {
    struct timeout_data *data = (struct timeout_data *)arg;
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec += data->timeout;

    pthread_mutex_lock(&mutex);
    while (!__atomic_load_n(&data->block_finished, __ATOMIC_SEQ_CST) &&
           !__atomic_load_n(&data->timeout_occurred, __ATOMIC_SEQ_CST) &&
           !__atomic_load_n(&data->signal_received, __ATOMIC_SEQ_CST)) {
        int res = pthread_cond_timedwait(&cond, &mutex, &ts);
        if (res == ETIMEDOUT) {
            __atomic_store_n(&data->timeout_occurred, 1, __ATOMIC_SEQ_CST);
            pthread_kill(data->main_thread, SIGALRM);
            break;
        }
    }
    pthread_mutex_unlock(&mutex);
    return NULL;
}

/**
 * @brief Signal handler for SIGALRM.
 *
 * Raises a Ruby exception if timeout occurred.
 *
 * @param signum The signal number (SIGALRM)
 */
static void sigalrm_handler(int signum) {
    if (__atomic_load_n(&global_timeout_data->timeout_occurred, __ATOMIC_SEQ_CST)) {
        rb_raise(rb_eTimeoutError, "execution expired");
    }
}

/**
 * @brief Ruby method: RubyTimeoutSafe.timeout(seconds)
 *
 * Executes a given block with a specified timeout.
 *
 * @param self The Ruby module (RubyTimeoutSafe)
 * @param seconds The timeout duration in seconds (Fixnum, Bignum, or nil)
 * @return The result of the block execution, or raises Timeout::Error if the timeout occurred
 */
static VALUE ruby_timeout_safe_timeout(VALUE self, VALUE seconds) {
    time_t timeout;
    if (NIL_P(seconds)) {
        timeout = 0;
    } else if (FIXNUM_P(seconds)) {
        timeout = FIX2LONG(seconds);
    } else if (RB_TYPE_P(seconds, T_BIGNUM)) {
        timeout = NUM2LL(seconds);
    } else {
        timeout = NUM2LONG(seconds);
    }

    if (timeout < 1) {
        rb_raise(rb_eArgError, "timeout value must be at least 1 second");
    }

    struct timeout_data data = {
        .timeout = timeout,
        .timeout_occurred = 0,
        .block_finished = 0,
        .signal_received = 0,
        .main_thread = pthread_self()
    };

    pthread_mutex_lock(&global_data_mutex);
    global_timeout_data = &data;
    pthread_mutex_unlock(&global_data_mutex);

    /* Set up signal handlers for SIGTERM, SIGINT, and SIGALRM */
    struct sigaction sa, old_sa_term, old_sa_int, old_sa_alrm;
    sigemptyset(&sa.sa_mask);
    sa.sa_handler = signal_handler;
    sa.sa_flags = 0;
    if (sigaction(SIGTERM, &sa, &old_sa_term) == -1 ||
        sigaction(SIGINT, &sa, &old_sa_int) == -1) {
        pthread_mutex_lock(&global_data_mutex);
        global_timeout_data = NULL;
        pthread_mutex_unlock(&global_data_mutex);
        rb_sys_fail("sigaction");
    }

    sa.sa_handler = sigalrm_handler;
    if (sigaction(SIGALRM, &sa, &old_sa_alrm) == -1) {
        sigaction(SIGTERM, &old_sa_term, NULL);
        sigaction(SIGINT, &old_sa_int, NULL);
        pthread_mutex_lock(&global_data_mutex);
        global_timeout_data = NULL;
        pthread_mutex_unlock(&global_data_mutex);
        rb_sys_fail("sigaction");
    }

    /* Create timeout thread */
    pthread_t timeout_thread;
    if (pthread_create(&timeout_thread, NULL, timeout_function, &data) != 0) {
        sigaction(SIGTERM, &old_sa_term, NULL);
        sigaction(SIGINT, &old_sa_int, NULL);
        sigaction(SIGALRM, &old_sa_alrm, NULL);
        pthread_mutex_lock(&global_data_mutex);
        global_timeout_data = NULL;
        pthread_mutex_unlock(&global_data_mutex);
        rb_raise(rb_eRuntimeError, "Failed to create timeout thread");
    }

    VALUE result;
    int state;

    /* Execute the Ruby block with protection */
    result = rb_protect(rb_yield, Qnil, &state);

    /* Signal that the block has finished */
    __atomic_store_n(&data.block_finished, 1, __ATOMIC_SEQ_CST);

    /* Wake up the timeout thread */
    pthread_mutex_lock(&mutex);
    pthread_cond_signal(&cond);
    pthread_mutex_unlock(&mutex);

    /* Wait for the timeout thread to finish */
    pthread_join(timeout_thread, NULL);

    /* Restore the original signal handlers */
    sigaction(SIGTERM, &old_sa_term, NULL);
    sigaction(SIGINT, &old_sa_int, NULL);
    sigaction(SIGALRM, &old_sa_alrm, NULL);

    pthread_mutex_lock(&global_data_mutex);
    global_timeout_data = NULL;
    pthread_mutex_unlock(&global_data_mutex);

    /* Check if timeout occurred or signal was received */
    if (__atomic_load_n(&data.timeout_occurred, __ATOMIC_SEQ_CST) ||
        __atomic_load_n(&data.signal_received, __ATOMIC_SEQ_CST)) {
        rb_raise(rb_eTimeoutError, "execution expired");
    }

    /* Handle any Ruby exceptions raised within the block */
    if (state) {
        rb_jump_tag(state);
    }

    return result;
}

/**
 * @brief Cleanup function to be called when the Ruby process exits.
 */
static void cleanup_timeout_safe(void) {
    pthread_mutex_destroy(&mutex);
    pthread_cond_destroy(&cond);
    pthread_mutex_destroy(&global_data_mutex);
}

/**
 * @brief Function to be called after fork in the child process.
 *
 * Reinitializes the mutex, condition variable, and global_timeout_data
 * in the forked child process.
 */
static void reinit_after_fork(void) {
    pthread_mutex_init(&mutex, NULL);
    pthread_cond_init(&cond, NULL);
    pthread_mutex_init(&global_data_mutex, NULL);
    global_timeout_data = NULL;
}

/**
 * @brief Initialization function for the Ruby extension.
 *
 * Sets up the RubyTimeoutSafe module and defines the timeout method.
 * Defines the Timeout::Error exception if it is not already defined.
 * Registers the cleanup and post-fork functions.
 */
void Init_ruby_timeout_safe(void) {
    VALUE mRubyTimeoutSafe = rb_define_module("RubyTimeoutSafe");

    /* Define Timeout::Error if not already defined */
    VALUE timeout_module = rb_define_module("Timeout");
    VALUE rb_eRuntimeError = rb_const_get(rb_cObject, rb_intern("RuntimeError"));
    if (!rb_const_defined(timeout_module, rb_intern("Error"))) {
        rb_eTimeoutError = rb_define_class_under(timeout_module, "Error", rb_eRuntimeError);
    } else {
        rb_eTimeoutError = rb_const_get(timeout_module, rb_intern("Error"));
    }

    rb_define_singleton_method(mRubyTimeoutSafe, "timeout", ruby_timeout_safe_timeout, 1);

    /* Register cleanup function */
    atexit(cleanup_timeout_safe);

    /* Register post-fork function */
    pthread_atfork(NULL, NULL, reinit_after_fork);
}
