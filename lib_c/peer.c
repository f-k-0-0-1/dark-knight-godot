#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#ifdef _WIN32
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#pragma comment(lib, "ws2_32.lib")
	#define CLOSE_SOCKET closesocket
#else
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <arpa/inet.h>
	#include <netdb.h>
	#include <unistd.h>
	#define CLOSE_SOCKET close
	typedef int SOCKET;
	#define INVALID_SOCKET -1
	#define SOCKET_ERROR -1
#endif

#define REQUIRED_ARGS_COUNT 4
#define EXIT_SUCCESS_CODE 0
#define EXIT_FAILURE_CODE -1

/* Explicitly initialize socket subsystems for compatibility with Windows. */
int initSockets(void)
{
#ifdef _WIN32
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
	{
		return EXIT_FAILURE_CODE;
	}
#endif
	return EXIT_SUCCESS_CODE;
}

int main(int argc, char const* argv[])
{
	if (argc < REQUIRED_ARGS_COUNT)
	{
		return EXIT_FAILURE_CODE;
	}

	const char* serverHost = argv[1];
	int serverPort = (int)atoi(argv[2]);
	const char* dataToSend = argv[3];

	SOCKET clientSocket = INVALID_SOCKET;
	struct sockaddr_in serverAddress;

	if (initSockets() != EXIT_SUCCESS_CODE)
	{
		return EXIT_FAILURE_CODE;
	}

	clientSocket = socket(AF_INET, SOCK_STREAM, 0);
	if (clientSocket == INVALID_SOCKET)
	{
#ifdef _WIN32
		WSACleanup();
#endif
		return EXIT_FAILURE_CODE;
	}

	memset(&serverAddress, 0, sizeof(serverAddress));
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_port = htons((uint16_t)serverPort);

	struct hostent* serverHostEntry = gethostbyname(serverHost);
	if (serverHostEntry == NULL)
	{
		CLOSE_SOCKET(clientSocket);
#ifdef _WIN32
		WSACleanup();
#endif
		return EXIT_FAILURE_CODE;
	}

	memcpy(&serverAddress.sin_addr.s_addr, serverHostEntry->h_addr_list[0], (size_t)serverHostEntry->h_length);

	if (connect(clientSocket, (struct sockaddr*)&serverAddress, (socklen_t)sizeof(serverAddress)) == SOCKET_ERROR)
	{
		CLOSE_SOCKET(clientSocket);
#ifdef _WIN32
		WSACleanup();
#endif
		return EXIT_FAILURE_CODE;
	}

	/* Send the raw data variable over the socket stream */
	size_t dataLength = strlen(dataToSend);
	send(clientSocket, dataToSend, (int)dataLength, 0);

	CLOSE_SOCKET(clientSocket);
#ifdef _WIN32
	WSACleanup();
#endif

	return EXIT_SUCCESS_CODE;
}
