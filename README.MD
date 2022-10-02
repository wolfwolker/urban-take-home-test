# Homework task for Urban

The goal of the task is to demonstrate how a candidate can create an environment with terraform. You should commit little and often to show your ways of working

## Requirements

- The environment should get created in Google Cloud Platform
- Create a VPC native Kubernetes cluster
- Host the provided Node.js application provided in the `app` folder in the created cluster with 3 replicas
- Use Terraform to orchestrate the deployment of the application
- Expose the provided application to the public internet
- Include at least 1 custom module in Terraform
- Add the prometheus-client to the provided application and expose one metric on a `/metrics` endpoint
- Write down some thoughts about what compromises you've applied (if any) and how would you like to improve the solution

# What gets evaluated

- Code quality
- Solution architecture
- Whether the code is "production-ready" (i.e. the environment starts and works as expected)
- How the code would scale to multiple environments
- Showing your work via the git commit history

Please share a Github link. If you want to keep it private, share it with the following users:
- rodolfobc
- gileze33


# What has been done an rough times

- Created a Dockerfile for the app, I found a couple problems related to the ts packaging file (if I'm not wrong the commands on it were for windows) and a lack of content in the readme. After solving that, added the prometheus client and the config for the githu pipelines. About 2-3h including the pipelines to build and push the docker image to the github registry.
- Second step was to build the cluster locally with minikube, deploy the app and add also argocd for the continuous delivery. About 1,5h
- Last step was to orchestate everything with terraform in gcp, in this step I've spent easily 4h to get familiar with gcp APIs, account setup, quotas and limits, etc.

## ToDos

- So, what we have is a repository with a folder for terraform, another one for the k8s manifests and a third one for the app. Imho this is not ideal at all and there should be 2 or 3 repositories, having terraform in one repo, the app in a second one, and the manifest either on a third repo or living with the app.
- the tfstate file should be in a shared storage, to be able to work as a team. For now is in my local and gitignored.
- terraform itself should be executed from somewhere else, like a bastionhost, and it could even have its own pipelines to auto apply changes in the code. Also there should be workspaces for different environments/cluster and more variables.
- the commands to setup argocd are relying on my laptop gcp and argocd binaries, so maybe all those commands should run inside a container or instance in the cloud, that would make it more secure because the communication would be through intranet.
- Of course, I should not rely on argocd default admin password and it should be changed/removed.
- Kustomize could be used to parametrize the manifests to allow more flexibility and different environments.
- Right now, the app is only deployed automatically if there are changes in the manifests, not in the image itself, we should improve that as well.