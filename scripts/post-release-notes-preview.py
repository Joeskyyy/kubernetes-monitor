#!/usr/local/bin/python3

import os
import requests
import subprocess
import sys

BRANCH_PREFIXES_TO_POST = ['feat', 'fix', 'chore', 'test', 'docs', 'revert']
GIT_BRANCH = os.environ['CIRCLE_BRANCH']
gitBranchParts = GIT_BRANCH.split('/')
if len(gitBranchParts) <= 1:
    sys.exit(0)

gitBranchPrefix = gitBranchParts[0]
if not gitBranchPrefix in BRANCH_PREFIXES_TO_POST:
    sys.exit(0)

SLACK_WEBHOOK = os.environ['SLACK_WEBHOOK']
USERNAME = os.environ.get('CIRCLE_USERNAME', 'USER_NOT_FOUND')

# last version:
lastVersion = subprocess.check_output(['git', 'describe', '--abbrev=0', '--tags', 'origin/staging'], text=True).strip()

# commits since last version
missingCommitsHeaders = subprocess.check_output(['git', 'log', '--no-decorate', lastVersion + '..HEAD', '--oneline'], text=True).strip()

# TODO: handle reverts?
features = []
fixes = []
others = []

lines = missingCommitsHeaders.split('\n')
for line in lines:
    words = line.split(' ')
    hash = words[0]
    prefix = words[1]
    rest = ' '.join(words[2:])

    title = ''.join(rest) + ' (%s)' % hash
    if prefix == 'feat:':
        features.append(title)
    elif prefix == 'fix:':
        fixes.append(title)
    else:
        others.append(title)

if not (features or fixes):
    sys.exit(0)

titleToPost = "Kubernetes-Monitor Proposed Release Notes (by %s)" % USERNAME
textToPost = ''
if features:
    textToPost += 'features:\n' + '\n'.join(features)
if fixes:
    textToPost += 'fixes:\n' + '\n'.join(fixes)
if others:
    textToPost += 'others (will not be included in Semantic-Release notes):\n' + '\n'.join(others)

requestBody = {
    "attachments": [
        {
            "title": titleToPost,
            "text": textToPost,
        }
    ]
}

requests.post(
    SLACK_WEBHOOK,
    json=requestBody,
)
