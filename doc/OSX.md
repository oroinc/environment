# OS X

## Requirements

- https://github.com/Homebrew/brew
- https://github.com/caskroom/homebrew-cask

```
brew install bash coreutils readline parallel md5sha1sum
PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
```

## Docker for Mac

[Docker for Mac](https://www.docker.com/docker-mac) performs 1.5x slower in average. 
Use [Xhyve](#Xhyve) as an alternative if you are not satisfied with performance.

```
brew cask install docker
docker --version
```

> Version 17.03.0-ce-mac1 (15583)
Channel: stable


```
brew cask install docker-beta
docker --version
```

> Version 17.04.0-ce-mac7 (16352)
Channel: edge

- https://forums.docker.com/t/file-access-in-mounted-volumes-extremely-slow-cpu-bound/8076
- https://github.com/docker/for-mac/issues/77

## Xhyve

```
brew install --HEAD xhyve
brew install docker docker-compose docker-machine
sudo chown root:wheel /usr/local/bin/docker-machine-driver-xhyve
sudo chmod u+s /usr/local/bin/docker-machine-driver-xhyve
docker-machine create --driver=xhyve --xhyve-memory-size=12192 --xhyve-cpu-count=6 --xhyve-virtio-9p --xhyve-experimental-nfs-share default
eval (docker-machine env default)

```

- https://github.com/mist64/xhyve
- https://github.com/zchee/docker-machine-driver-xhyve
- https://allysonjulian.com/posts/setting-up-docker-with-xhyve/

## Parallels Desktop

```
brew cask install parallels-desktop
brew install docker-machine-parallels
docker-machine create --driver=parallels --parallels-memory=12192 --parallels-cpu-count=6 default
eval (docker-machine env default)
```

- http://kb.parallels.com/en/123356
- https://github.com/Parallels/docker-machine-parallels
