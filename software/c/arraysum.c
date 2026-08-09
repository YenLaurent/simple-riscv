int main() {
    volatile int *result = (volatile int*)0x200;
    volatile int arr[5];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;
    volatile int sum = 0;
    for (int i = 0; i < 5; i++) {
        sum += arr[i];
    }
    *result = sum;
    while (1);
}
