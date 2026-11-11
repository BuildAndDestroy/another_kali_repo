#!/bin/bash
set -e

YAML_FILE="./kali-config/common/hooks/tools.yaml"
HOOK_DIR="./kali-config/common/hooks/live/"

# Ensure yq is installed
if ! command -v yq &> /dev/null; then
  echo "[-] yq is not installed. Install it with: sudo apt install yq"
  exit 1
fi

mkdir -p "$HOOK_DIR"
echo "[*] Generating hook scripts from $YAML_FILE..."

tool_count=$(yq '.tools | length' "$YAML_FILE")

for (( i=0; i<$tool_count; i++ )); do
  name=$(yq ".tools[$i].name" "$YAML_FILE" | tr -d '"')
  type=$(yq ".tools[$i].type" "$YAML_FILE" | tr -d '"')
  repo=$(yq ".tools[$i].repo" "$YAML_FILE" | tr -d '"')
  bin=$(yq ".tools[$i].bin" "$YAML_FILE" | tr -d '"')
  go_path=$(yq ".tools[$i].go_path" "$YAML_FILE" | tr -d '"')
  venv=$(yq ".tools[$i].venv" "$YAML_FILE" | tr -d '"')
  wordlist=$(yq ".tools[$i].wordlist" "$YAML_FILE" | tr -d '"')
  outname=$(yq ".tools[$i].outname" "$YAML_FILE" | tr -d '"')

  pyversion=$(yq ".tools[$i].pyversion" "$YAML_FILE" | tr -d '"')
  [[ -z "$pyversion" || "$pyversion" == "null" ]] && pyversion="3"

  if [[ "$pyversion" == "3.11" ]]; then
    chmod +x "$HOOK_DIR"90-python3.11-installer.hook.chroot
  fi

  HOOK_FILE="${HOOK_DIR}99-${name}.hook.chroot"

  case "$type" in
    git+python)
      echo "[*] Creating hook for $name (Python)..."

      if [[ "$venv" == "true" ]]; then
        # Resolved at generation time and baked into the hook
        if [[ "$pyversion" == "3.11" ]]; then
          pybin="/usr/local/bin/python3.11"
          apt_pkgs="git python3-pip build-essential libyaml-dev curl"
        else
          pybin="python3"
          apt_pkgs="git python3-pip python3-venv python3-dev build-essential libyaml-dev curl"
        fi

        if [[ "$name" == "pacu" ]]; then
	  bin="cli.py"
	fi

        # NOTE: unquoted heredoc - escape anything that must be evaluated
        # when the hook runs (\$, \$@) rather than now.
        cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name using $pybin..."

apt update -y
apt install -y $apt_pkgs

cd /opt
git clone $repo $name
cd $name

$pybin -m venv venv
source venv/bin/activate

pip install --upgrade pip setuptools wheel cython
if [[ -f requirements.txt ]]; then
  pip install -r requirements.txt || true
else
  # Projects without requirements.txt (e.g. pacu) ship pyproject/setup.py
  pip install .
fi

# Wrapper in PATH
cat <<'EOW' > /usr/local/bin/$name
#!/bin/bash
source /opt/$name/venv/bin/activate
/opt/$name/venv/bin/python /opt/$name/$bin "\$@"
EOW

chmod +x /usr/local/bin/$name
echo "[+] $name installed using $pybin."
EOF
      else
        cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name globally..."

apt update
apt install -y git python3-pip

cd /opt
git clone $repo $name
cd $name

if [[ -f requirements.txt ]]; then
  pip3 install --break-system-packages -r requirements.txt || true
else
  pip3 install --break-system-packages .
fi
ln -sf /opt/$name/$bin /usr/local/bin/$name

echo "[+] $name installed globally."
EOF
      fi

      chmod +x "$HOOK_FILE"
      ;;

    git+pipenv)
      echo "[*] Creating hook for $name (Pipenv)..."

      if [[ "$venv" == "true" ]]; then
        cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name with pipenv..."

apt update
apt install -y git pipenv python3 python3-pip

cd /opt
git clone $repo $name
cd $name

pipenv install --skip-lock || true

# Wrapper in PATH
cat <<'EOW' > /usr/local/bin/$name
#!/bin/bash
cd /opt/$name
exec pipenv run python $bin "\$@"
EOW

chmod +x /usr/local/bin/$name

echo "[+] $name installed via pipenv."
EOF
      else
        cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name without pipenv..."

apt update
apt install -y git pipenv python3 python3-pip

cd /opt
git clone $repo $name
cd $name

pipenv install --skip-lock || true
ln -sf /opt/$name/$bin /usr/local/bin/$name

echo "[+] $name installed with direct symlink."
EOF
      fi

      chmod +x "$HOOK_FILE"
      ;;

    git+bash)
      echo "[*] Creating hook for $name (Bash)..."
      cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name..."
apt update
apt install -y git
cd /opt
git clone $repo $name
EOF
      [[ "$bin" != "null" && "$bin" != "" ]] && echo "ln -sf /opt/${name}/${bin} /usr/local/bin/${name}" >> "$HOOK_FILE"
      ;;

    go)
      echo "[*] Creating hook for $name (Go)..."
      cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name..."
apt update
apt install -y golang
export GOPATH=/root/go
go install $go_path@latest
install -Dm755 /root/go/bin/${name} /usr/local/bin/${name}
EOF
      ;;

    make+go)
      echo "[*] Creating hook for $name (make+Go)..."

      if [[ -z "$outname" || "$outname" == "null" ]]; then
        outname=$name
      fi

      cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name (built via Makefile)..."

apt update
apt install -y git golang make curl

cd /opt
git clone $repo $name
cd $name

make build

# Symlink the binary to /usr/local/bin
install -Dm755 $bin /usr/local/bin/$outname

echo "[+] $name installed as $outname."
EOF

      chmod +x "$HOOK_FILE"

      # Add optional wordlist compilation if set
      if [[ "$wordlist" == "true" ]]; then
        echo "cd /opt/$name" >> "$HOOK_FILE"
	echo "mkdir wordlists" >> "$HOOK_FILE"
	echo "curl -L https://wordlists-cdn.assetnote.io/rawdata/kiterunner/routes-small.json.tar.gz -o wordlists/routes-small.json.tar.gz" >> "$HOOK_FILE"
	echo "curl -L https://wordlists-cdn.assetnote.io/rawdata/kiterunner/routes-large.json.tar.gz -o wordlists/routes-large.json.tar.gz" >> "$HOOK_FILE" 
	echo "tar -xzf wordlists/routes-small.json.tar.gz -C wordlists" >> "$HOOK_FILE"
	echo "tar -xzf wordlists/routes-large.json.tar.gz -C wordlists" >> "$HOOK_FILE"
        echo "./dist/kr kb compile wordlists/routes-small.json wordlists/routes-small.kite" >> "$HOOK_FILE"
	echo "./dist/kr kb compile wordlists/routes-large.json wordlists/routes-large.kite" >> "$HOOK_FILE"
	echo "rm wordlists/routes*.json" >> "$HOOK_FILE"
	echo "rm wordlists/routes-*.tar.gz" >> "$HOOK_FILE"
        echo "echo '[+] Wordlists compiled'" >> "$HOOK_FILE"
      fi
      ;;


    git)
      echo "[*] Creating hook for $name (Git repo only)..."
      cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name (clone only)..."
apt update
apt install -y git
cd /opt
git clone $repo $name
EOF
      [[ "$bin" != "null" && "$bin" != "" ]] && echo "ln -sf /opt/${name}/${bin} /usr/local/bin/${name}" >> "$HOOK_FILE"
      ;;

    rust)
      echo "[*] Creating hook for $name (Rust)..."
      cat <<EOF > "$HOOK_FILE"
#!/bin/bash
set -e
echo "[*] Installing $name (Rust)..."
apt update
apt install -y curl build-essential pkg-config libssl-dev
curl https://sh.rustup.rs -sSf | sh -s -- -y
source \$HOME/.cargo/env
cargo install $name
ln -sf /root/.cargo/bin/$name /usr/local/bin/$name
EOF
      ;;

    *)
      echo "[!] Skipping unsupported type for $name: $type"
      continue
      ;;

  esac

  echo 'echo "[+] '"$name"' installed."' >> "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
done

echo "[✓] Hook generation complete."


