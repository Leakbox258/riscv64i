int main() {
  int a[0x10];
  a[0] = 0xffeeddcc;
  a[0xf] = a[0];
  return 0;
}
