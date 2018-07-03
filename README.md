## REQUIREMENTS

jq


## USAGE

### Login

```
    login.sh {USER} {PASSWORD}
```

### List projects

```
    projects.sh [-u {USER} -p {PASSWORD}] [-t {TOKEN}]
```

### List project versions

```
    versions.sh [-u {USER} -p {PASSWORD}] [-t {TOKEN}] [-o {PROJECT_EXTERNAL_ID}]
```

### List project issues

```
    issues.sh [-u {USER} -p {PASSWORD}] [-t {TOKEN}] [-o {PROJECT_EXTERNAL_ID}] [-v {VERSION_EXTERNAL_ID}] [-d {NUMBER_OF_DAYS}] [-c {TYPE_OF_ISSUE}] [-s {STATUS}]
```

### List issue sessions

```
    issue.sh [-u {USER} -p {PASSWORD}] [-t {TOKEN}] [-o {PROJECT_EXTERNAL_ID}] [-i {ISSUE_EXTERNAL_ID}] [-d {NUMBER_OF_DAYS}] [-C {SHOULD_CONSOLIDATE_RESULTS}
```
### Consolidate issue sessions

```
    consolidate.sh -f {PATH_TO_SESSIONS_JSON}
```