#include<pthread.h>
#include<stdio.h>

void *print_hello(void *data) {
    printf("Hello from thread %ld\n", (long)data);
    pthread_exit(NULL);
}

int main() {
    pthread_t threads[2];
    long t;

    for (t = 0; t < 2; t++) {
        printf("In main: creating thread %ld\n", t);
        pthread_create(&threads[t], NULL, print_hello, (void *)t);
    }

    for (t = 0; t < 2; t++) {
        pthread_join(threads[t], NULL);
    }

    pthread_exit(NULL);
}