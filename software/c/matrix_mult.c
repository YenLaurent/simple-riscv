// matrix_mult.c — 2×K × K×2 矩阵乘：脉动阵列加速器 vs CPU 纯软件路径
// 编译时用 -DMODE=0 / -DMODE=1 选择路径（默认 0）
//   路径 0: 加速器（写 A/B → 写 K → start → 轮询 done → 读 lo/hi 结果）
//   路径 1: CPU 三重循环 + 软件乘法（RV32I 无 mul 指令）
// 期望值由 CPU 参考实现（soft_mul）计算一次，两种路径共用同一份自检
// 自检结果写入 DMEM:
//   0x200 = 0x600 表示全部通过，否则为出错次数
//   0x204 = 第一次出错的轮次  0x208 = 第一次出错的元素下标
//   0x20C-0x218 = 最后一轮的 C00..C11
//   0x2FC = 0xC0DE 程序结束标记（TB 监测后自动 $finish 并打印统计）

#define A_BASE   0x300   // A 第 0 行（K 个元素连续存放）
#define A1_BASE  0x340   // A 第 1 行
#define B_BASE   0x380   // B 第 0 列（K 个元素连续存放）
#define B1_BASE  0x3C0   // B 第 1 列
#define ACC_CTRL 0x400   // 写 bit0=1 触发 start；读 bit0 = done（粘性标志）
#define ACC_K    0x404   // 内积维 K（1..K_MAX）

#define C00_LO 0x408
#define C00_HI 0x40C
#define C01_LO 0x410
#define C01_HI 0x414
#define C10_LO 0x418
#define C10_HI 0x41C
#define C11_LO 0x420
#define C11_HI 0x424

#define K_TEST 8          // 测试用的内积维

#ifndef MODE
#define MODE 0
#endif

// 软件乘法：移位-加法。用 unsigned 保证 >> 生成逻辑右移 srl
unsigned int soft_mul(unsigned int a, unsigned int b) {
    unsigned int r = 0;
    while (b) {
        if (b & 1) r += a;
        a <<= 1;
        b >>= 1;
    }
    return r;
}

// CPU 参考实现：MODE 0 用它算期望值，MODE 1 用它作为被测路径
// A 布局: [0..K-1]=第0行, [K..2K-1]=第1行；B 布局: [0..2K-1] 交错存放列0/列1
void cpu_matmul(int K, volatile int* A, volatile int* B, volatile int* C) {
    int i, j, k;
    for (i = 0; i < 2; i++)
        for (j = 0; j < 2; j++) {
            int sum = 0;
            for (k = 0; k < K; k++)
                sum += soft_mul(A[i*K + k], B[k*2 + j]);
            C[i*2 + j] = sum;
        }
}

#if MODE == 0
// 加速器路径
void acc_matmul(int K, volatile int* A, volatile int* B, volatile int* C) {
    volatile int *acc_ctrl = (volatile int*)ACC_CTRL;
    volatile int *acc_k    = (volatile int*)ACC_K;
    int i;
    for (i = 0; i < K; i++) *(volatile int*)(A_BASE  + 4*i) = A[i];        // A 第0行
    for (i = 0; i < K; i++) *(volatile int*)(A1_BASE + 4*i) = A[K + i];    // A 第1行
    for (i = 0; i < K; i++) *(volatile int*)(B_BASE  + 4*i) = B[2*i];      // B 第0列
    for (i = 0; i < K; i++) *(volatile int*)(B1_BASE + 4*i) = B[2*i + 1];  // B 第1列
    *acc_k = K;                        // 必须在 start 之前写 K
    *acc_ctrl = 1;                     // 触发 start
    while ((*acc_ctrl & 1) == 0);      // 轮询 done（sticky 标志，不会错过）
    // 读回 64 位结果（本测试数据小，hi 应为 0；hi 非零则以 -1 标记错误）
    C[0] = *(volatile int*)C00_LO;  if (*(volatile int*)C00_HI != 0) C[0] = -1;
    C[1] = *(volatile int*)C01_LO;  if (*(volatile int*)C01_HI != 0) C[1] = -1;
    C[2] = *(volatile int*)C10_LO;  if (*(volatile int*)C10_HI != 0) C[2] = -1;
    C[3] = *(volatile int*)C11_LO;  if (*(volatile int*)C11_HI != 0) C[3] = -1;
}
#endif

int main() {
    volatile int A[2*K_TEST];
    volatile int B[2*K_TEST];
    volatile int C[4];
    int expected[4];
    int i, run, errors = 0;

    // 数据（元素级赋值，避免编译器生成 memcpy 调用）:
    // A[0][i]=i+1, A[1][i]=K+i+1, B[i][0]=i+1, B[i][1]=K+i+1
    for (i = 0; i < K_TEST; i++) {
        A[i]         = i + 1;
        A[K_TEST+i]  = K_TEST + i + 1;
        B[2*i]       = i + 1;
        B[2*i+1]     = K_TEST + i + 1;
    }

    // 期望值：CPU 参考实现计算一次（K=8 时: c00=204, c01=c10=492, c11=1292）
    cpu_matmul(K_TEST, A, B, expected);

#if MODE == 0
    const int runs = 10;    // 加速器快，多跑几轮
#else
    const int runs = 3;     // 软件乘法慢，少跑几轮
#endif

    for (run = 0; run < runs; run++) {
#if MODE == 0
        acc_matmul(K_TEST, A, B, C);
#else
        cpu_matmul(K_TEST, A, B, C);
#endif
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
    *(volatile int*)0x20C = C[0];
    *(volatile int*)0x210 = C[1];
    *(volatile int*)0x214 = C[2];
    *(volatile int*)0x218 = C[3];

    // 结束标记：TB 监测到此写操作后自动 $finish 并打印 mcycle/minstret
    *(volatile int*)0x2FC = 0xC0DE;
    while (1);
}
