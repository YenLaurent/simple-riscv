int main() {
    volatile int *result = (volatile int*)0x200;
    int a = 0, b = 1;
    for (int i = 0; i < 10; i++) {
        int c = a + b;
        a = b;
        b = c;
    }
    *result = b;  // 10th Fibonacci number = 89
    while (1);
}
