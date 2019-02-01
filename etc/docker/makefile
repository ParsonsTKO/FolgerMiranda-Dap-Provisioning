requirements: ## Installing local requirements
ifeq ($(shell uname), Darwin)
	grep -q 'brew' <<< echo `command -v brew` || /usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew install make git git-crypt gpg
	brew cask install docker
	open -a Docker
else ifeq ($(shell uname), Linux)
	sudo sh -c "$$(curl -fsSL https://get.docker.com)"
	sudo apt-get install make git git-crypt gpg
	sudo usermod -aG docker $${USER}
	sudo service docker start
	sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$$(uname -s)-$$(uname -m) -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	su - $${USER}
else ifeq ($(shell uname), Windows_NT)
	@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
	choco install make git docker-for-windows -y
else
	$(warning Platform not supported)
endif

install:
	git-crypt unlock
	make exec command="$(install)"

init: ## Initialize Terraform modules and plugins
	make exec command="$(init)"

plan: ## Preview the changes to the plan
	make exec command="$(plan)"

apply: ## Preview the changes to the plan, then optionally execute the plan
	make exec command="$(apply)"

destroy: ## !!! Destroy all resources
	make exec command="$(destroy)"

exec:
	make cli cli_command="-c \"$(command)\""

cli:
	@docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -it --entrypoint "" hashicorp/terraform:0.11.11 /bin/ash $(cli_command)

terraform: ## Execute Terraform commands
	make exec command="terraform $(o)"
