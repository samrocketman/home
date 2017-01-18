/*
Originally obtained from:
https://github.com/samrocketman/drexel-university/blob/master/appserver-scripts/sslTest.java

The MIT License (MIT)

Copyright (c) 2012 Samuel Gleske, Drexel University

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
import java.net.*;
import java.io.*;
import java.security.*;
import javax.net.ssl.*;

public class sslTest {
	public static void main(String[] args) {
		if (args.length < 2) {
			System.out.println("Usage: java sslTest somehost someport");
			return;
		}

		int port = 0;
		if(args[1] == null){
			port = 443; // default https port
		}else{
			port = Integer.parseInt(args[1]);
		}
		String host = args[0];

		try{
			Security.addProvider(new com.sun.net.ssl.internal.ssl.Provider());
			SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();

			SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
			SSLSession session = socket.getSession();
			System.out.println("Protocol is " + session.getProtocol());
			// just close it
			System.out.println("Closing connection.");
			socket.close();
		}catch (IOException e) {
			System.err.println(e);
		}
	}
}
