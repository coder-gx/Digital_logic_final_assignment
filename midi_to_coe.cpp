#include<iostream>
#include<fstream>
#include<iomanip>
using namespace std;

int main()
{
	ifstream in("E:\\pythonfiles\\wav_to_coe\\Ⱥ��-YOASOBI.mid", ios::in | ios::binary);
	int wid = 4;
	int ch;
	int cnt = 0;//��¼���˶����ֽ�
	cout << "memory_initialization_radix=16;\nmemory_initialization_vector = " << endl;
	while ((ch = in.get()) != EOF)
	{
		cout << setw(2) <<setfill('0')<< hex << ch;
		cnt++;

		if (cnt % 4==0) {
			cout << "," << endl;
		}
	}
	in.close();

	return 0;
}