#include "udpShim.hpp"

using namespace std;

int main() {
	stream<axiWord>      	rxDataIn("rxDataIn");
    stream<metadata>     	rxMetadataIn("rxMetadataIn");
    stream<extendedAxiWord> rxDataOut("rxDataOut");
	stream<ap_uint<16> >    requestPortOpenOut("requestPortOpenOut");
	stream<bool > 			portOpenReplyIn("portOpenReplyIn");
	stream<extendedAxiWord> txDataIn("txDataIn");
	stream<axiWord> 		txDataOut("txDataOut");
	stream<metadata> 		txMetadataOut("txMetadataOut");
	stream<ap_uint<16> > 	txLengthOut("txLengthOut");

	stream<extendedAxiWord>	bufferQueue("bufferQueue");
	uint32_t	packetLength = 0;
	extendedAxiWord inData;

	ifstream inputFile;
	ofstream outputFile;

	static ap_uint<32> ipAddress = 0x01010101;
	
	inputFile.open("../../../../in.dat");
	if (!inputFile) {
		cout << "Error: could not open test input file." << endl;
		return -1;
	}

	outputFile.open("../../../../out.dat");
	if (!outputFile) {
		cout << "Error: could not open test output file." << endl;
		return -1;
	}

	uint32_t count = 0;
	uint16_t keepTemp;
	uint64_t dataTemp;
	uint16_t lastTemp;
	for (uint8_t i=0;i<10;++i) {

		udpShim(rxDataIn, rxMetadataIn, rxDataOut, requestPortOpenOut, portOpenReplyIn,
				txDataIn, txDataOut, txMetadataOut, txLengthOut, 11211);
		if (!requestPortOpenOut.empty()) {
			requestPortOpenOut.read();
			portOpenReplyIn.write(true);
		}
	}
	while (inputFile >> std::hex >> dataTemp >> lastTemp >> keepTemp) {
		inData.data = dataTemp;
		inData.last = lastTemp;
		inData.keep = keepTemp;
		inData.user.range(63,0) = 0x2BCB0101010AAA7A;
		inData.user.range(111,64) = 0x001D01010101;
		txDataIn.write(inData);
		count++;
	}
	count = 0;
	while (!txDataIn.empty() || count < 1000) {
		udpShim(rxDataIn, rxMetadataIn, rxDataOut, requestPortOpenOut, portOpenReplyIn,
				txDataIn, txDataOut, txMetadataOut, txLengthOut, 11211);
		if (txDataIn.empty())
			count++;
		axiWord outData = {0, 0, 0};
		while (!(txDataOut.empty())) {
			 // Get the DUT result
			txDataOut.read(outData);
			 // Write DUT output to file
			outputFile << hex << noshowbase;
			outputFile << setfill('0');
			outputFile << setw(16) << outData.data << " " << setw(2) << outData.keep << " ";
			outputFile << setw(1) << outData.last << endl;
		}
	}
	inputFile.close();
	outputFile.close();
	return 0;
}
