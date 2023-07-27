
set -o errexit
set -o nounset
set -o pipefail

export KO_DOCKER_REPO=docker.io/chunyineko
readonly version=0.10.0
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

mkdir -p bundle/.imgpkg
mkdir -p bundle/config
mkdir -p bundle/samples

cp LICENSE "bundle/LICENSE"
cp NOTICE "bundle/NOTICE"
cp VERSION "bundle/VERSION"
cp config/carvel/bundle.yaml "bundle/bundle.yaml"
cp -r samples "bundle/samples"

echo "##[group]Build Service Bindings"
  cp hack/boilerplate/boilerplate.yaml.txt bundle/config/service-bindings.yaml
  ko resolve -t ${slug} -t latest -B -f config \
    | ytt -f - -f config/carvel/release-version.overlay.yaml \
        --data-value version=${slug} \
    >> bundle/config/service-bindings.yaml
  kbld -f bundle/config/service-bindings.yaml --imgpkg-lock-output bundle/.imgpkg/images.yml
echo "##[endgroup]"

echo "##[group]Create bundle"
  imgpkg push -f "bundle" -b "docker.io/chunyineko/sbtesting:v0.10.0"
  imgpkg copy -b "docker.io/chunyineko/sbtesting:v0.10.0" --to-tar bundle/service-bindings-bundle.tar
echo "##[endgroup]"
