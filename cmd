make_certs:all().

client [client]: openssl s_client -connect 127.0.0.1:4433 -cert cert.pem -key key.pem -CAfile cacerts.pem -status -tls1_2
server[a.server]: openssl s_server -cert cert.pem -key key.pem -CAfile cacerts.pem -status_verbose -status_url http://127.0.0.1:8080 -tls1_2
ocsp responder[b.server]: openssl ocsp -index ../otpCA/index.txt -CA cacerts.pem -rsigner cert.pem -rkey key.pem -port 8080
