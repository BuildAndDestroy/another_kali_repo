# another_kali_repo
Kali repo for tooling and automation


## Preparation

* Update the HTTP server with your IP address of where you will host the preseed.cfg file
* Add your SHA512 encrypted password to the preseed.cfg file.

```
mkpasswd -m sha-512
```

## Dockerfile

You will need to build this on a Kali machine
```
[*] On a Kali vm
	docker build -t kali-unattended-builder:1 .
	sudo docker run --rm -it --privileged -v /home/kali/images:/root/live-build-config/images kali-unattended-builder:1 ./build.sh --variant xfce --verbose
```


## To Do

* Kali's live build is not injecting the preseed.cfg file into the finished iso, need to debug and get that working.


# Resources:

* https://gitlab.com/kalilinux/recipes/kali-preseed-examples
* https://www.kali.org/docs/development/live-build-a-custom-kali-iso/
* https://www.kali.org/docs/development/dojo-mastering-live-build/
