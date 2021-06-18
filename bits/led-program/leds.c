#define INF 0x299d68
#define uint unsigned int
#define LED_ADDR 0xbfaff000

void pause() {
    int i = 0;
    while (i < INF) i++;
}

void display(uint p) {
    uint* ptr;
    ptr = (uint*) LED_ADDR;
    (*ptr) = p;
}

int main() {
    uint k = 1;
    while (1) {
        display(k);
        k = (k << 1) | (~(k >> 15));
        pause();
    }
    return 0;
}
