#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#ifdef _WIN32
	#include <winsock2.h>
	#include <ws2tcpip.h>
	#pragma comment(lib, "ws2_32.lib")
	typedef int socklen_t;
	#define CLOSE_SOCKET closesocket
#else
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <unistd.h>
	#define CLOSE_SOCKET close
	typedef int SOCKET;
	#define INVALID_SOCKET -1
	#define SOCKET_ERROR -1
#endif

#define BUFFER_SIZE 4096
#define PRIMARY_PORT 8080
#define SECONDARY_PORT 8081
#define BACKLOG_LIMIT 1
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
	if (initSockets() != EXIT_SUCCESS_CODE)
	{
		return EXIT_FAILURE_CODE;
	}

	int port = 0;
	if (argc >= 2)
	{
		port = (int)atoi(argv[1]);
	}

	SOCKET serverSocket = INVALID_SOCKET;
	SOCKET clientSocket = INVALID_SOCKET;
	struct sockaddr_in serverAddress;
	socklen_t addressLength = (socklen_t)sizeof(serverAddress);
	char receiveBuffer[BUFFER_SIZE];

	/* Explicitly zero out memory buffers */
	memset(&serverAddress, 0, sizeof(serverAddress));
	memset(receiveBuffer, 0, BUFFER_SIZE);

	serverSocket = socket(AF_INET, SOCK_STREAM, 0);
	if (serverSocket == INVALID_SOCKET)
	{
#ifdef _WIN32
		WSACleanup();
#endif
		return EXIT_FAILURE_CODE;
	}

#ifndef _WIN32
	int socketOption = 1;
	setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, (const char*)&socketOption, (socklen_t)sizeof(socketOption));
#endif

	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = INADDR_ANY;
	
	if (port != 0)
	{
		/* Bind to the explicitly requested port */
		serverAddress.sin_port = htons((uint16_t)port);
		if (bind(serverSocket, (struct sockaddr*)&serverAddress, (socklen_t)sizeof(serverAddress)) == SOCKET_ERROR)
		{
			CLOSE_SOCKET(serverSocket);
#ifdef _WIN32
			WSACleanup();
#endif
			return EXIT_FAILURE_CODE;
		}
	}
	else
	{
		/* Fallback bind logic if no port is specified */
		serverAddress.sin_port = htons((uint16_t)PRIMARY_PORT);
		if (bind(serverSocket, (struct sockaddr*)&serverAddress, (socklen_t)sizeof(serverAddress)) == SOCKET_ERROR)
		{
			serverAddress.sin_port = htons((uint16_t)SECONDARY_PORT);
			if (bind(serverSocket, (struct sockaddr*)&serverAddress, (socklen_t)sizeof(serverAddress)) == SOCKET_ERROR)
			{
				CLOSE_SOCKET(serverSocket);
#ifdef _WIN32
				WSACleanup();
#endif
				return EXIT_FAILURE_CODE;
			}
		}
	}

	if (listen(serverSocket, BACKLOG_LIMIT) == SOCKET_ERROR)
	{
		CLOSE_SOCKET(serverSocket);
#ifdef _WIN32
		WSACleanup();
#endif
		return EXIT_FAILURE_CODE;
	}

	clientSocket = accept(serverSocket, (struct sockaddr*)&serverAddress, &addressLength);
	if (clientSocket == INVALID_SOCKET)
	{
		CLOSE_SOCKET(serverSocket);
#ifdef _WIN32
		WSACleanup();
#endif
		return EXIT_FAILURE_CODE;
	}

	/* Receive up to BUFFER_SIZE - 1 bytes to guarantee null-termination */
	int bytesReceived = recv(clientSocket, receiveBuffer, BUFFER_SIZE - 1, 0);
	if (bytesReceived > 0)
	{
		receiveBuffer[bytesReceived] = '\0';
		printf("%s", receiveBuffer); 
		fflush(stdout);
	}

	CLOSE_SOCKET(clientSocket);
	CLOSE_SOCKET(serverSocket);

#ifdef _WIN32
	WSACleanup();
#endif

	return EXIT_SUCCESS_CODE;
}
