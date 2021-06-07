## Github Action to create Release Pull Request with description generated form previous merged Feature Pull Requests

### Setup

```yaml
name: Release Pull Request Action

on:
  push:
    branches:
      - staging

jobs:
  build:
    name: Release Pull Request
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: mmnfst/release-pull-request-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.PAT }} # token of your account
          PULL_REQUEST_FEATURE_BRANCH: "staging"
          PULL_REQUEST_BASE_BRANCH: "master"
          PULL_REQUEST_REVIEWERS: DmitrySadovnikov,aderyabin
          PULL_REQUEST_ASSIGNEES: DmitrySadovnikov,aderyabin
          PULL_REQUEST_LABELS: Release,Review required
```

### Example

We have 2 merged pull requests to "staging" branch with descriptions.

First description:

```
## Bugfix

* Fix something
```

Second description:

```
## Features

* Add something
```

After we merged these pull requests to the staging branch, a pull request from staging to master with description will be automatically created:

```
## Features

* Add something

## Bugfix

* Fix something
```
