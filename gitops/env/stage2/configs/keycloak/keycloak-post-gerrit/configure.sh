#!/usr/bin/env bash

# Copyright (c) 2024-2025 Accenture, All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

npm install
node keycloak.mjs
SECRET=$(cat client-gerrit.json | jq -r ".secret")

ssh-keygen -t ecdsa -b 256 -f ./id_ecdsa -C "horizon-sdv" -N "" -q
SSH_KEY=$(cat id_ecdsa | base64 -w0)
SSH_KEY_PUB=$(cat id_ecdsa.pub | base64 -w0)

sed -i "s/##SECRET##/${SECRET}/g" ./secure.config
SECURE_CONFIG=$(cat secure.config | base64 -w0)

sed -i "s/##SECURE_CONFIG##/${SECURE_CONFIG}/g" ./secret.json
sed -i "s/##SSH_KEY##/${SSH_KEY}/g" ./secret.json
sed -i "s/##SSH_KEY_PUB##/${SSH_KEY_PUB}/g" ./secret.json

curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X DELETE ${APISERVER}/api/v1/namespaces/gerrit/secrets/gerrit-secure-config
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -H 'Accept: application/json' -H 'Content-Type: application/json' -X POST ${APISERVER}/api/v1/namespaces/gerrit/secrets -d @secret.json
