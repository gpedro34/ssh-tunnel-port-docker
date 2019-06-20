# SSH tunnel remote port to local port

This repository holds a Docker container image that runs an ssh command opening an SSH tunnel like so:
`ssh -L 0.0.0.0:2374:internal-hostname:2375 your-custom-hostname`
Explanation: Tunnel internal-hostname:2375 on your SSH server to 0.0.0.0:2374 on your Docker Host Network (**bridge** network driver, not the docker `host` network driver)

## Motivation - Exposing Docker daemons securely

I made this Docker container image in order to be able to connect any Docker host (Standalone, Swarm or DinD) to a Portainer container running on another Docker standalone Host on Windows 10.

Portainer is able to connect to a Docker daemon via either a TCP exposed connection or a Docker Unix socket mapped to some directory the Portainer container can reach.
Although with Docker for Windows, due to the fact that the Docker daemon with Docker for Windows is installed inside a Hyper-V VM, this means that:

- localhost is not the same host for you (localhost=your Windows machine) that is for your portainer container (localhost=Hyper-V VM (MobyLinuxVM))
- No ports are exposed from your localhost (Windows) environment into the Hyper-V VM running Docker (just the other way around)

Therefore, there was no way (at least that I could find) to connect a remote Docker daemon into portainer without exposing it throught TCP.
After some hours trying to understand the inner workings of what I've just explained the solution was kind of obvious...
You just need to ssh to your remote machine from somewhere reachable to the Portainer container, so, dockerize the SSH connection command and it should be reachable in your **bridge** connection.

## Usage

While this image was made to solve a problem I was having with my Portainer setup, this repository image can be used to proxy any port running on any remote server you can access throught SSH.

### Setup

1. Put your OpenSSH private key(s) inside **ssh/keys/** folder and the known hosts signature(s) of your server(s) inside the **known_hosts** file
2. Modify **ssh/config** file to suit your needs. The example configuration in [config](https://github.com/gpedro34/ssh-tunel-port-docker/blob/master/ssh/config) is for a user with Private Key authentication. See [OpenSSH configuration](https://www.ssh.com/ssh/config/)
3. Run `docker build . -t my-custom-image` to build your image with your secrets, and known hosts list already inside
4. Then run `docker run -d -e LOCAL_PORT=2374 -e SSH_HOST=your-custom-hostname -e REMOTE_HOST=internal-hostname -e REMOTE_PORT=2375 my-custom-image`

### Portainer configuration

1. Now you only need your **Portainer container Gateway address**. You can get it:
   - by inspecting the running portainer container
   - or thought the Portainer UI - **Containers => YOUR-PORTAINER => Connected Networks (bottom of the page)**
2. Now that you already have the Gateway address configure your new Docker endpoint like: `GATEWAY_ADDRESS:LOCAL_PORT`

### Environment Variables

| Variable    | Description                                                               |
| :---------- | :------------------------------------------------------------------------ |
| LOCAL_PORT  | Local port destination of the SSH tunnel                                  |
| SSH_HOST    | Host specified in the **ssh/config** file or a reachable domain via SSH\* |
| REMOTE_HOST | Remote host to tunnel to your local network                               |
| REMOTE_PORT | Remote port origin of the SSH tunnel                                      |

\* If you need to use other port than 22 you have to configure it in the **ssh/config** file or change the ssh command inside the Dockerfile to include the port flag `-p 1234`

### Some considerations to have when setting up with Portainer

- Use certificates without passphrase protection and provide the known_hosts list so the connection is completely automated and doesn't hang. If you are using it in interactive mode disregard this point...
- Portainer will only see the remote Docker server if the SSH connection is open, therefore you are provably better setting it up as part of your Portainer stack so it restarts automatically in case of Docker host restarts.
- Running this image with `docker run ...` command will expose the SSH tunnel inside the **default bridge network** (network that connects your docker daemon to your containers)
- Running this image with `docker-compose ...` command will expose the SSH tunnel inside the **default network created to your specific stack** so make sure to either include it in the stack you want to use, or by attaching the correct networks together
