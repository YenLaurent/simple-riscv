int main() {
    volatile int *dst_ptr  = (volatile int*)0x200;
    volatile int *dst_ptr2 = (volatile int*)0x204;
    volatile int src[4];
    src[0] = 1;
    src[1] = 2;
    src[2] = 3;
    src[3] = 4;
    volatile int dst[4];
    for (int i = 0; i < 4; i++) {
        dst[i] = src[i];
    }
    *dst_ptr  = dst[0];
    *dst_ptr2 = dst[3];
    while (1);
}
