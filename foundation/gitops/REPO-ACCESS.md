# Argo CD access to this private repository

Argo CD runs inside the cluster and must **read** this private repo to sync it.
That requires a credential, stored as a Secret in `openshift-gitops` carrying
the label `argocd.argoproj.io/secret-type: repository`. This is the one piece
that is applied **out of band** (not via GitOps) — it is the secret the GitOps
bootstrap needs before it can manage itself.

> **Current choice: HTTPS Personal Access Token (PAT).** Chosen for network
> robustness (HTTPS/443 is rarely blocked). The SSH deploy-key alternative is
> documented below and is the least-privilege option for a single repo; switch
> to it later without changing anything else in the platform.

## Security rules (apply to both options)

- The credential is a **Secret in the cluster**, never committed to Git.
- The token/key value lives only in your local `secret.env` (gitignored) and is
  applied idempotently with `--dry-run=client -o yaml | oc apply -f -`.
- Use **read-only**, **single-repo** scope. Argo CD only needs to read.
- Rotate on a schedule (PATs expire; see below).

---

## Option A — HTTPS Personal Access Token (current)

### 1. Create a fine-grained PAT on GitHub

Use a **fine-grained** token (not classic) so scope is one repo, read-only:

- GitHub → Settings → Developer settings → **Fine-grained personal access tokens**
  → Generate new token.
- **Resource owner:** your account (`sandrotanaka`).
- **Repository access:** Only select repositories → `showcase-app-platform`.
- **Permissions:** Repository permissions → **Contents: Read-only**. (That is all
  Argo CD needs to clone/read.)
- **Expiration:** pick a finite period (e.g. 90 days) and set a reminder to
  rotate. Avoid "no expiration".
- Generate and copy the token (starts with `github_pat_...`). You will not see it
  again.

### 2. Put the token in a local, gitignored env file

Create `foundation/gitops/repo-secret.env` (this name is gitignored — verify):

```
url=https://github.com/sandrotanaka/showcase-app-platform.git
username=sandrotanaka
password=github_pat_REPLACE_WITH_YOUR_TOKEN
type=git
```

> `username` can be your GitHub login; for fine-grained PATs the token in
> `password` is what authenticates. Never commit this file.

### 3. Apply it idempotently as an Argo CD repository Secret

```bash
oc create secret generic showcase-repo \
  --from-env-file=foundation/gitops/repo-secret.env \
  -n openshift-gitops \
  --dry-run=client -o yaml | \
oc label -f - --local -o yaml \
  argocd.argoproj.io/secret-type=repository | \
oc apply -f -
```

(The middle step adds the label Argo CD looks for. Re-running is safe.)

### 4. Verify Argo CD sees the repo

```bash
oc get secret showcase-repo -n openshift-gitops \
  -o jsonpath='{.metadata.labels.argocd\.argoproj\.io/secret-type}{"\n"}'
# -> repository
```

In the Argo CD UI (Settings → Repositories) the repo should show
**Successful** connection.

### Rotating the PAT

When the token nears expiry, generate a new one, update
`foundation/gitops/repo-secret.env`, and re-run step 3 (idempotent — it updates
the existing Secret in place).

---

## Option B — SSH deploy key (least privilege, no expiry)

Preferred for a single repo when outbound SSH (port 22) is allowed from the
cluster. A deploy key is scoped to **one repository** and can be **read-only**,
and it does not expire.

### 1. Generate a dedicated key pair (no passphrase)

```bash
ssh-keygen -t ed25519 -C "argocd-showcase-app-platform" \
  -f ./argocd_showcase_deploy_key -N ""
```

Produces `argocd_showcase_deploy_key` (private) and `.pub` (public). Keep the
private key out of Git.

### 2. Register the PUBLIC key as a read-only deploy key

GitHub → repo → Settings → **Deploy keys** → Add deploy key → paste the contents
of `argocd_showcase_deploy_key.pub`. **Leave "Allow write access" unchecked.**

### 3. Apply the PRIVATE key as an Argo CD repository Secret

```bash
oc create secret generic showcase-repo-ssh \
  --from-literal=type=git \
  --from-literal=url=git@github.com:sandrotanaka/showcase-app-platform.git \
  --from-file=sshPrivateKey=./argocd_showcase_deploy_key \
  -n openshift-gitops \
  --dry-run=client -o yaml | \
oc label -f - --local -o yaml \
  argocd.argoproj.io/secret-type=repository | \
oc apply -f -
```

### 4. Network caveat

If sync fails with a connection/timeout error, the cluster likely blocks
outbound SSH. Fall back to Option A (HTTPS PAT).

---

## Why this is applied by hand (not GitOps)

The repo credential is a secret, and secrets never go in Git. So this Secret —
together with the root App-of-Apps — is the minimal manual bootstrap. Once it
exists, Argo CD can read the repo and manage everything else declaratively.
