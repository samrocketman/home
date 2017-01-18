//javac 1.6.0_26
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
