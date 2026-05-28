# Ataque-POC

Proyecto académico para demostrar una vulnerabilidad de **reentrancy** en Solidity, explotarla con un contrato atacante y documentar su mitigación.

## Objetivo

- Entender cómo ocurre un ataque de reentrancy.
- Reproducir el exploit en un entorno local con Foundry.
- Aplicar buenas prácticas de seguridad para mitigarlo.

## Contexto del Ataque

El contrato vulnerable (`SimpleBanck.sol`) transfiere ETH al usuario **antes** de actualizar su saldo interno.

Patrón inseguro:
1. Interacción externa (`call`) primero.
2. Actualización de estado (`userBalance[msg.sender] = 0`) después.

Un atacante puede aprovechar ese orden para reingresar a `withdraw()` desde `receive()` y retirar fondos múltiples veces antes de que el saldo se ponga en cero.

## Contratos

- `src/SimpleBanck.sol`: contrato tipo banco vulnerable a reentrancy.
- `src/Atacante.sol`: contrato atacante que ejecuta la reentrada.

## Tecnologías

- [Foundry](https://book.getfoundry.sh/)
- Solidity `0.8.24`
- OpenZeppelin Contracts (instalado para mitigaciones, por ejemplo `ReentrancyGuard`)

## Instalación

Desde la carpeta del proyecto:

```bash
forge install
```

Si querés reinstalar OpenZeppelin explícitamente:

```bash
forge install OpenZeppelin/openzeppelin-contracts
```

## Compilar

```bash
forge build
```

## Tests

```bash
forge test -vv
```

Nota: este repositorio ya incluye el entorno para que puedas agregar pruebas del escenario vulnerable y del escenario mitigado.

## Flujo del Exploit (Reentrancy)

1. El atacante deposita ETH en el banco.
2. Llama a `withdraw()`.
3. El banco envía ETH con `call` al atacante.
4. Se ejecuta `receive()` del atacante.
5. `receive()` vuelve a llamar `withdraw()` mientras el balance interno aún no fue puesto en `0`.
6. El ciclo se repite hasta drenar el contrato (o hasta no cumplir condición mínima).

## Mitigaciones Recomendadas

1. **Checks-Effects-Interactions (CEI)**
- Primero validar (`require`).
- Segundo actualizar estado interno.
- Tercero interactuar con contratos externos.

2. **ReentrancyGuard (OpenZeppelin)**
- Heredar de `ReentrancyGuard`.
- Proteger funciones sensibles con `nonReentrant`.

3. **Diseño defensivo adicional**
- Evitar lógica compleja en `receive()`/`fallback()`.
- Considerar patrón pull-over-push para retiros.

## Advertencia

Este código es únicamente con fines educativos de ciberseguridad y auditoría. **No usar en producción** sin auditoría profesional y controles adicionales.

## Próximos pasos sugeridos

- Agregar test de exploit exitoso en `test/`.
- Agregar versión mitigada del banco y test comparativo.
- Documentar resultados (balance antes/después) en este mismo README.

## Autor

Trabajo académico PoC - Reentrancy Attack.
