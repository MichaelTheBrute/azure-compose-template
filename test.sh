#!/bin/bash

# Loop through services in docker-compose.yml and configure replicas and ingress
for SERVICE in $(yq -r '.services | keys | .[]' docker-compose.yml); do
    echo "Processing service: $SERVICE"

    # Extract custom labels
    MIN_REPLICAS=$(yq -r ".services.${SERVICE}.labels[]? | select(test(\"^studiologic.io.min-replicas=\")) | split(\"=\")[1]" docker-compose.yml)
    INGRESS_TYPE=$(yq -r ".services.${SERVICE}.labels[]? | select(test(\"^studiologic.io.ingress.type=\")) | split(\"=\")[1]" docker-compose.yml)

    # Default values if labels are not set
    MIN_REPLICAS=${MIN_REPLICAS:-1}
    INGRESS_TYPE=${INGRESS_TYPE:-external}

    # Print out the parsed values
    echo "  Min Replicas: $MIN_REPLICAS"
    echo "  Ingress Type: $INGRESS_TYPE"

done
echo "All services processed."
