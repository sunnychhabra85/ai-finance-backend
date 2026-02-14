# Local Development with Docker Compose

This Docker Compose setup simulates the entire production architecture locally.

## Prerequisites

- Docker Desktop (version 20.10+)
- Docker Compose (version 2.0+)
- At least 4GB RAM available for Docker

## Quick Start

### 1. Setup Environment Variables

```bash
cd infra/docker-compose
cp .env.example .env
# Edit .env and add your OpenAI API key if needed