aws eks describe-addon-versions --addon-name external-dns --kubernetes-version 1.33

#{
#    "addons": [
#        {
#            "addonName": "external-dns",
#            "type": "networking",
#            "addonVersions": [
#                {
#                    "addonVersion": "v0.18.0-eksbuild.1",
#                    "architecture": [
#                        "amd64",
#                        "arm64"
#                    ],
#                    "computeTypes": [
#                        "auto",
#                        "ec2",
#                        "fargate"
#                    ],
#                    "compatibilities": [
#                        {
#                            "clusterVersion": "1.33",
#                            "platformVersions": [
#                                "*"
#                            ],
#                            "defaultVersion": true
#                        }
#                    ],
#                    "requiresConfiguration": false,
#                    "requiresIamPermissions": true
#                },
#                {
#                    "addonVersion": "v0.17.0-eksbuild.2",
#                    "architecture": [
#                        "amd64",
#                        "arm64"
#                    ],
#                    "computeTypes": [
#                        "auto",
#                        "ec2",
#                        "fargate"
#                    ],
#                    "compatibilities": [
#                        {
#                            "clusterVersion": "1.33",
#                            "platformVersions": [
#                                "*"
#                            ],
#                            "defaultVersion": false
#                        }
#                    ],
#                    "requiresConfiguration": false,
#                    "requiresIamPermissions": true
#                },
#                {
#                    "addonVersion": "v0.17.0-eksbuild.1",
#                    "architecture": [
#                        "amd64",
#                        "arm64"
#                    ],
#                    "computeTypes": [
#                        "auto",
#                        "ec2",
#                        "fargate"
#                    ],
#                    "compatibilities": [
#                        {
#                            "clusterVersion": "1.33",
#                            "platformVersions": [
#                                "*"
#                            ],
#                            "defaultVersion": false
#                        }
#                    ],
#                    "requiresConfiguration": false,
#                    "requiresIamPermissions": true
#                },
#                {
#                    "addonVersion": "v0.16.1-eksbuild.2",
#                    "architecture": [
#                        "amd64",
#                        "arm64"
#                    ],
#                    "computeTypes": [
#                        "auto",
#                        "ec2",
#                        "fargate"
#                    ],
#                    "compatibilities": [
#                        {
#                            "clusterVersion": "1.33",
#                            "platformVersions": [
#                                "*"
#                            ],
#                            "defaultVersion": false
#                        }
#                    ],
#                    "requiresConfiguration": false,
#                    "requiresIamPermissions": true
#                }
#            ],
#            "publisher": "eks",
#            "owner": "community"
#        }
#    ]
#}
