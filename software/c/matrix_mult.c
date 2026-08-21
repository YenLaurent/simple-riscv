// matrix_mult.c — 2×2 矩阵乘：脉动阵列加速器 vs CPU 纯软件路径
// 编译时用 -DMODE=0 / -DMODE=1 选择路径（默认 0）
//   路径 0: 加速器（写 A/B → start → 轮询 done → 读结果）
//   路径 1: CPU 三重循环 + 软件乘法（RV32I 无 mul 指令）
// 自检结果写入 DMEM:
//   0x200 = 0x600 表示全部通过，否则为出错次数
//   0x204 = 第一次出错的轮次  0x208 = 第一次出错的元素下标
//   0x20C-0x218 = 最后一轮计算出的 C00..C11（期望 19/22/43/50）
//   0x2FC = 0xC0DE 程序结束标记（TB 监测后自动 $finish 并打印统计）

#define ACC_A      0x300   // A00-A11（连续 4 字）
#define ACC_B      0x310   // B00-B11（连续 4 字）
#define ACC_CTRL   0x320   // 写 bit0=1 触发 start；读 bit0 = done
#define ACC_RES    0x324   // C00-C11（连续 4 字）

#ifndef MODE
#define MODE 0
#endif

// 软件乘法：移位-加法（小学乘法）
// 用 unsigned 保证 >> 生成逻辑右移 srl（有符号 int 会生成算术右移 sra）
unsigned int soft_mul(unsigned int a, unsigned int b) {
    unsigned int r = 0;
    while (b) {
        if (b & 1) r += a;   // b 的最低位为 1 就累加当前 a
        a <<= 1;             // a 左移一位 = 乘 2
        b >>= 1;             // b 右移一位 = 检查下一位
    }
    return r;
}

#if MODE == 0
// 加速器路径
void matmul(volatile int* A, volatile int* B, volatile int* C) {
    volatile int *acc  = (volatile int*)ACC_A;
    volatile int *ctrl = (volatile int*)ACC_CTRL;
    volatile int *res  = (volatile int*)ACC_RES;
    int i;
    for (i = 0; i < 4; i++) acc[i]     = A[i];   // 写 A00..A11
    for (i = 0; i < 4; i++) acc[i + 4] = B[i];   // 写 B00..B11
    *ctrl = 1;                                    // 触发 start
    while ((*ctrl & 1) == 0);                     // 轮询 done（sticky 标志）
    for (i = 0; i < 4; i++) C[i] = res[i];        // 读回 C00..C11
}
#else
// CPU 纯软件路径：三重循环 + 软件乘法
void matmul(volatile int* A, volatile int* B, volatile int* C) {
    int i, j, k;
    for (i = 0; i < 2; i++)
        for (j = 0; j < 2; j++) {
            int sum = 0;
            for (k = 0; k < 2; k++)
                sum += soft_mul(A[2*i + k], B[2*k + j]);
            C[2*i + j] = sum;
        }
}
#endif

int main() {
    volatile int A[4];
    volatile int B[4];
    volatile int C[4];
    int expected[4];
    int i, run, errors = 0;

    // 元素级赋值初始化（整体初始化会触发编译器调用 memcpy，8/9 的教训）
    A[0]=1; A[1]=2; A[2]=3; A[3]=4;
    B[0]=5; B[1]=6; B[2]=7; B[3]=8;
    // C = A×B = [[19 22] [43 50]]
    expected[0]=19; expected[1]=22; expected[2]=43; expected[3]=50;

#if MODE == 0
    const int runs = 10;    // 加速器快，多跑几轮
#else
    const int runs = 3;     // 软件乘法慢，少跑几轮
#endif

    for (run = 0; run < runs; run++) {
        matmul(A, B, C);
        for (i = 0; i < 4; i++)
            if (C[i] != expected[i]) {
                errors++;
                if (errors == 1) {                    // 只记录第一次出错的位置
                    *(volatile int*)0x204 = run;      // 第几轮
                    *(volatile int*)0x208 = i;        // 第几个元素
                }
            }
    }

    // 自检状态区
    *(volatile int*)0x200 = (errors == 0) ? 0x600 : errors;
    *(volatile int*)0x20C = C[0];   // 19
    *(volatile int*)0x210 = C[1];   // 22
    *(volatile int*)0x214 = C[2];   // 43
    *(volatile int*)0x218 = C[3];   // 50

    // 结束标记：TB 监测到此写操作后自动 $finish 并打印 mcycle/minstret
    *(volatile int*)0x2FC = 0xC0DE;
    while (1);
}
