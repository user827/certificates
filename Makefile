# CSR creation

.PRECIOUS: %_ecparam.pem
%_ecparam.pem:
	openssl ecparam -name prime256v1 -out "$@"

.PRECIOUS: %.key
ifeq ($(keytype),rsa)
%.key:
	openssl genrsa -out "$@" 2048
else
%.key: %_ecparam.pem
	openssl genpkey -paramfile "$<" -out "$@"
endif

.PRECIOUS: %.csr
%.csr: %.key
	openssl req -new -key "$<" -out "$@" -config "$*".cnf


# CA creation

.PRECIOUS: ca.key
ifeq ($(ca_keytype),rsa)
ca.key:
	openssl genrsa -aes256 -out "$@" 2048
else
ca.key: ca_ecparam.pem
	openssl genpkey -aes256 -paramfile "$<" -out "$@"
endif

.PRECIOUS: ca.csr
ca.csr: ca.key ca.cnf
	openssl req -new -key "$<" -out "$@" -config ca.cnf -reqexts v3_ca_req

.PRECIOUS: ca.db.index
ca.db.index:
	touch "$@"

.PRECIOUS: newcerts
newcerts:
	mkdir newcerts

.PRECIOUS: ca.crt
ca.crt: ca.csr ca.cnf | ca.db.index newcerts
	openssl ca -create_serial -selfsign -config ca.cnf -keyfile ca.key -in "$<" -out "$@" -extensions v3_ca


# CRT signing

.PRECIOUS: %.crt
%.crt: %.csr ca.crt | ca.db.index newcerts
	openssl ca -config ca.cnf -in "$<" -out "$@"


# Misc

.PHONY: clean
clean:
	rm -f *.crt newcerts/* *.key *.out ca.db* *.old *.csr *.pem

.PHONY: showcert
showcert:
	openssl x509 -in $(c).crt -text

.PHONY: showremotecert
showremotecert:
	openssl s_client -connect $(c) </dev/null 2>/dev/null | openssl x509 -inform pem -text
