#!/usr/bin/env bash
set -e

# we are going to setup different GitHub Actions workflows on
#   GitHub repo '${repoName}' under GitHub user account '${userName}'
#   which has Write access to the repo

# to trigger 'webhook' event with help of 'curl' command we use
#   'Authorization' header with personal access token '${token}' which
#   has to be created aforehand, see [2] 

userName=kalsmic
userEmail=kalulearthur@gmail.com
repoName=learn_git_workflows
token="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"

# create, init, and configure git repo
# mkdir repo
# cd repo

# git init
# git config  user.email ${userEmail}
# git config  user.name ${userName}
# git remote add origin https://github.com/${userName}/${repoName}.git # create new GitHub repo preliminarily

# create GitHub Actions workflows dir
mkdir -p .github/workflows

# [A] create workflow for 'webhook' event
cat > .github/workflows/webhook.yaml << '_EOF'
name: workflow-webhook
on: repository_dispatch
jobs:
  job-webhook:
    runs-on: ubuntu-latest
    steps:
    - name: "step-checkout"
      uses: actions/checkout@v1
    - name: "step-log"
      if: github.event.action == 'A'
      run: |
        echo "[A] github.ref: ${{github.ref}}"
_EOF

# add, commit, and push the changes
git add .
git commit -m "save changes: webhook workflow"
git push -u origin main

# [B] create workflow for 'push main branch' event
cat > .github/workflows/main.yaml << '_EOF'
name: workflow-main
on:
  push:
    branches:
      - "main"
jobs:
  job-main:
    runs-on: ubuntu-latest
    steps:
    - name: "step-checkout"
      uses: actions/checkout@v1
    - name: "step-log"
      run: |
        echo "[B] github.ref: ${{github.ref}}"
_EOF

# [C] create workflow for 'push tags' event
cat > .github/workflows/tags.yaml << '_EOF'
name: workflow-tags
on:
  push:
    tags:
      - "v*.*.*"
jobs:
  job-tags:
    runs-on: ubuntu-latest
    steps:
    - name: "step-checkout"
      uses: actions/checkout@v1
    - name: "step-log"
      run: |
        echo "[C] github.ref: ${{github.ref}}"
_EOF

# add, commit, and push changes
git add .
git commit -m "save changes: push commit + push tags workflows"
git push

sleep 5

# trigger 'push main branch' event to run 'workflow-main'
touch B0
git add B0
git commit -m "B0"
git push origin refs/heads/main:refs/heads/main

# GHA item: "B0, workflow-main #...: Commit 4c4e5b7 pushed by user"
# output: "[B] github.ref: refs/heads/main"

# trigger 'push tags' event to run 'workflow-tags'
git tag -a "v0.C.0" -m "C0"
git push origin refs/tags/v0.C.0:refs/tags/v0.C.0

# GHA item: "B0, workflow-tags #...: Commit 4c4e5b7 pushed by user"
# output: "[C] github.ref: refs/tags/v0.C.0"

sleep 5

# trigger 'push main branch' and 'push tags' events at the same time
touch B1
git add B1
git commit -m "B1"
git tag -a "v0.C.1" -m "C1"
git push origin refs/heads/main:refs/heads/main refs/tags/v0.C.1:refs/tags/v0.C.1

# GHA item: "B1, workflow-main #...: Commit 650067f pushed by user"
# output: "[B] github.ref: refs/heads/main"

# GHA item: "B1 workflow-tags #...: Commit 650067f pushed by user"
# output: "[C] github.ref: refs/tags/v0.C.1"

# we need to make 'workflow-tags' be dependent on 'workflow-main' avoiding code duplication
rm .github/workflows/main.yaml
rm .github/workflows/tags.yaml
git add .
git commit -m "save changes: remove individual workflows"
git push

# [D] create combined workflows for 'push main branch' and 'push tags' events
#   'push main branch' should build and test
#   'push tags' should build, test and deploy
cat > .github/workflows/build-test-deploy.yaml << '_EOF'
name: workflow-build-test-deploy
on:
  push:
    branches:
      - "main"
    tags:
      - "v*.*.*"
jobs:
  job-build-test:
    runs-on: ubuntu-latest
    steps:
    - name: "step-checkout"
      uses: actions/checkout@v1
    - name: "step-log"
      run: |
        echo "[D] job-build-test: github.ref: ${{github.ref}}"
  job-deploy:
    runs-on: ubuntu-latest
    needs:
      - job-build-test
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
    - name: "step-checkout"
      uses: actions/checkout@v1
    - name: "step-log"
      run: |
        echo "[D] job-deploy: github.ref: ${{github.ref}}"
_EOF

# add, commit, and push changes
git add .
git commit -m "save changes: build-test-deploy workflow"
git push

sleep 5

# trigger build and test
touch D0
git add D0
git commit -m "D0"
git push origin refs/heads/main:refs/heads/main

# GHA item: "D0, workflow-build-test-deploy #2: Commit 5b83775 pushed by user"
# output: "[D] job-build-test: github.ref: refs/heads/main"

# trigger build, test, and deploy
git tag -a "v0.D.0" -m "v0.D.0"
git push origin refs/tags/v0.D.0:refs/tags/v0.D.0

# GHA item: "D0, workflow-build-test-deploy #3: Commit 5b83775 pushed by user"
# output: "[D] job-build-test: github.ref: refs/tags/v0.D.0"
# output: "[D] job-deploy: github.ref: refs/tags/v0.D.0"

sleep 5

# pushing commit together with tag will trigger 'job-build-test' twice
touch D1
git add D1
git commit -m "D1"
git tag -a "v0.D.1" -m "v0.D.1"
git push origin refs/heads/main:refs/heads/main refs/tags/v0.D.1:refs/tags/v0.D.1

# GHA item: "D1 workflow-build-test-deploy #4: Commit a67851e pushed by user"
# output: "[D] job-build-test: github.ref: refs/heads/main"

# GHA item: "D1 workflow-build-test-deploy #5: Commit a67851e pushed by user"
# output: "[D] job-build-test: github.ref: refs/tags/v0.D.1"
# output: "[D] job-deploy: github.ref: refs/tags/v0.D.1"

sleep 5

# use the following command to trigger 'webhook' event and run 'workflow-webhook' (see [1])
curl -X POST "https://api.github.com/repos/${userName}/${repoName}/dispatches" \
  -H "Accept: application/vnd.github.everest-preview+json" \
  -H "Authorization: token ${token}" \
  --data '{"event_type": "A"}'

# GHA item: "A, workflow-webhook #...: Repository dispatch triggered by user"
# output: "[A] github.ref: refs/heads/main"

# [1] https://help.github.com/en/actions/reference/events-that-trigger-workflows#external-events-repository_dispatch
# [2] https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line