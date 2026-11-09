# bot-luxidle-nim ⚡

Automação autônoma nativa para **Lux Idle Online** reescrita 100% em **Nim 2.2** com modelo de gerenciamento de memória ORC (`--mm:orc`), zero overhead de Garbage Collector e ultra-baixo consumo de memória RAM.

## 🚀 Destaques da Arquitetura Nim
- **100% Paridade de Heurística e Métricas**: Compatível com as métricas JSON de telemetria expostas na porta padrão (`3012`) sob `/api/status`.
- **Motor Anti-Detecção com Pacing e Jitter Orgânico**: Variação randômica de $\pm 20\%$ nos intervalos de caça e ações para evitar assinaturas temporais determinísticas.
- **Operação 24/7 Contínua sem Pausas Forçadas**: Otimizado para jogabilidade de idle contínua.
- **Protocolo Nativo WebSocket**: Handshake de sessão, auto-seleção de personagem, auto-party, bênçãos, munição na aljava, venda de loot e diárias.
- **Consumo de Memória Extremamente Reduzido**: Binário estático e compacto compilado via Zig toolchain.

## 📦 Compilação
```bash
nim c --os:linux --cpu:amd64 --gcc.exe:zigcc-linux-gnu.bat --gcc.linkerexe:zigcc-linux-gnu.bat -d:ssl -d:release -o:bot-luxidle-linux-nim main.nim
```

## ⚙️ Configuração
Copie `accounts.example.json` para `accounts.json` e insira as credenciais do seu personagem:
```json
[
  {
    "id": "lux-1",
    "name": "Knight Principal",
    "enabled": true,
    "credentials": {
      "token": "seu-token-de-sessao-ou-jwt",
      "email": "user@exemplo.com",
      "password": "senha-segura",
      "characterName": "Knight 219"
    },
    "settings": {
      "hunt_target": "auto",
      "auto_hunt": true,
      "auto_sell": true,
      "auto_bless": true,
      "auto_daily": true,
      "auto_quiver": true
    }
  }
]
```
