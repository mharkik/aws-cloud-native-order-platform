# AWS Cloud Native Order Platform

Grundstruktur für eine cloudnative Bestellplattform auf AWS.

```text
aws-cloud-native-order-platform/
├── services/
│   ├── customer-service/
│   │   ├── pom.xml
│   │   └── src/
│   ├── product-service/
│   │   ├── pom.xml
│   │   └── src/
│   ├── order-service/
│   │   ├── pom.xml
│   │   └── src/
│   └── notification-service/
│       ├── pom.xml
│       └── src/
├── infrastructure/
│   └── terraform/
├── deployment/
│   ├── kubernetes/
│   ├── helm/
│   └── argocd/
├── monitoring/
├── docker/
├── docs/
│   ├── architecture/
│   ├── adr/
│   ├── security/
│   └── troubleshooting/
├── .gitignore
└── README.md
```

Die Services enthalten jeweils eine minimale Maven-Projektdatei. Leere
Verzeichnisse werden durch `.gitkeep` in Git erhalten.
