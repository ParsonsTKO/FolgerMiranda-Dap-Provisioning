.PHONY: all

docker_image ?= hashicorp/terraform:0.11.7

ifeq ($(UNAME), Darwin)
requirements:
	grep -q 'brew' <<< echo `command -v brew` || /usr/bin/ruby -e "`curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install`"
	brew install make git terraform git-crypt gpg
endif

ifeq ($(UNAME), Linux)
requirements:
  sudo apt-get install make git terraform git-crypt gpg -y
endif

ifeq ($(UNAME), Windows_NT)
requirements:
	@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
	choco install make git terraform git-crypt gpg -y
endif

install:
	git-crypt unlock
	$(install)

plan:
	$(plan)

apply:
	$(apply)

destroy:
	$(destroy)
