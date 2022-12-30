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

## Running on a debian container - Kali host no longer needed
```
	docker build -t kali-debian-build --network=host -f debian-docker.dockerfile . 
	sudo docker run --rm -it --privileged --network=host -v /home/codonnell/development/git/another_kali_repo/images:/root/live-build-config/images -v /proc:/proc kali-debian-build:latest ./build.sh --variant xfce --verbose
```

## To Do

* Investigate the security url, I believe we can remove this from the preseed file


# Resources:

* https://gitlab.com/kalilinux/recipes/kali-preseed-examples
* https://www.kali.org/docs/development/live-build-a-custom-kali-iso/
* https://www.kali.org/docs/development/dojo-mastering-live-build/
