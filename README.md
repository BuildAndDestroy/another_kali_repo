# another_kali_repo
Kali repo for tooling and automation


## Preparation

* Update the HTTP server with your IP address of where you will host the preseed.cfg file
* Add your SHA512 encrypted password to the preseed.cfg file.

```
mkpasswd -m sha-512
```

## Dockerfile

Now works on Kali and Ubuntu
```
	sudo docker build -t kali-unattended-builder:1 .

	# For Linux/Ubuntu OS
	sudo docker run --rm -it --privileged -v /home/ubuntu/git/another_kali_repo/images:/opt/live-build-config/images kali-unattended-builder:1 ./build.sh --variant xfce --verbose

	# For Kali OS
	sudo docker run --rm -it --privileged -v /home/kali/images:/opt/live-build-config/images kali-unattended-builder:1 ./build.sh --variant xfce --verbose
```


# Resources:

* https://gitlab.com/kalilinux/recipes/kali-preseed-examples
* https://www.kali.org/docs/development/live-build-a-custom-kali-iso/
* https://www.kali.org/docs/development/dojo-mastering-live-build/
