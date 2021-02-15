default: test

export COMMIT=${CI_COMMIT_SHORT_SHA}
export TRAVIS_BRANCH=${CI_COMMIT_REF_NAME}
export TRAVIS_EVENT_TYPE=${CI_PIPELINE_SOURCE}
export TRAVIS_REPO_SLUG=${CI_PROJECT_PATH}
export TRAVIS_BUILD_NUMBER=${CI_COMMIT_SHORT_SHA}
export COMPOSE_INTERACTIVE_NO_CLI=1

###########################################################
## atalhos docker-compose build e push para o Docker Hub ##
###########################################################

release_docker_build:
        @echo "[Building] Release version: " $(OPAC_WEBAPP_VERSION)
        @echo "[Building] Latest commit: " $(OPAC_VCS_REF)
        @echo "[Building] Build date: " $(OPAC_BUILD_DATE)
        @echo "[Building] Image full tag: $(TRAVIS_REPO_SLUG):$(COMMIT)"
        @docker build \
        -t $(CI_REGISTRY)/$(TRAVIS_REPO_SLUG):$(COMMIT) .

release_docker_tag:
        @echo "[Tagging] Target image -> $(TRAVIS_REPO_SLUG):$(COMMIT)"
        @echo "[Tagging] Image name:latest -> $(TRAVIS_REPO_SLUG):latest"
        @docker tag $(CI_REGISTRY)/$(TRAVIS_REPO_SLUG):$(COMMIT) $(CI_REGISTRY)/$(TRAVIS_REPO_SLUG):latest

release_docker_push:
        @echo "[Pushing] pushing image: $(TRAVIS_REPO_SLUG)"
        @docker push $(CI_REGISTRY)/$(TRAVIS_REPO_SLUG):$(COMMIT)
        @docker push $(CI_REGISTRY)/$(TRAVIS_REPO_SLUG):latest
        @echo "[Pushing] push $(CI_REGISTRY)/$(TRAVIS_REPO_SLUG) done!"
