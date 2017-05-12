# Ubuntu/Debian environment setup guide

1. Install base packages and tools
    ```
    sudo apt-get install -y git curl resolvconf dnsutils coreutils realpath bash parallel
    ```

2. Install latest docker

    ```
    curl -L https://get.docker.com | sudo bash
    ```

3. Install docker-compose
    ```
    sudo curl -L "https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    ```

4. Add current user to docker group  
    ```
    sudo usermod -aG docker $USER
    ```

5. Log in to a docker group

    ```
    newgrp docker
    ```
    
    > Note: This work only for the current shell session. To did it permanently you must re login.

6. Get the docker interface ip address  

    ```
    export DOCKER0_IP=`ip addr | grep docker0 | grep "inet" | head -n1 | awk '{ print $2 }' | cut -d/ -f1`
    ```
    Starting dns-gen container
    ```
    docker run --name dns-gen --restart always --dns=8.8.8.8 --dns=8.8.4.4 -d -p ${DOCKER0_IP}:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock oroinc/docker-dns-gen
    ```
    > you can to change ips for dns if needed
    
    Check dns-gen is running
    ```
    docker ps
    ```
    > 2436ea91b642        oroinc/docker-dns-gen   "governator -D"     28 seconds ago      Up 27 seconds       172.17.0.1:53->53/udp   dns-gen

7. Setup dns-gen container ip as primary DNS server and update resolv.conf  

    ```
    echo "nameserver ${DOCKER0_IP}" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
    ```
    Reload resolv.conf
    ```
    sudo resolvconf -u
    ```

8. Verify is the docker dns works correctly. 
    ```
    host dns-gen.docker
    ```
    > Must return result like this: `dns-gen.docker has address 172.x.x.x`
    
9. Getting SSH access to GitHub by follow instructions on [this page](https://help.github.com/articles/connecting-to-github-with-ssh/).
