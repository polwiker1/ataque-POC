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

## PoC 3: Delegatecall Takeover

### Idea en lenguaje humano

`delegatecall` es como ejecutar un "manual externo" pero escribiendo dentro de tu propio contrato.
Si cualquiera puede cambiar ese manual (implementación), un atacante puede poner uno malicioso y reescribir variables críticas como `owner`.

### Contratos

- `src/DelegatecallProxyVulnerable.sol`: proxy vulnerable (permite cambiar implementación sin control de acceso).
- `src/MaliciousDelegate.sol`: implementación maliciosa que toma ownership.
- `src/DelegatecallProxySafe.sol`: versión segura con `onlyOwner` y validaciones básicas.

### Qué muestra el test

- En vulnerable: el atacante cambia implementación + ejecuta `delegatecall` y se vuelve owner.
- En seguro: el atacante no puede cambiar implementación (`Only owner`) y el takeover falla.

### Comandos

```bash
forge test --match-path test/Delegatecall.t.sol -vvvv
forge test --match-path test/DelegatecallSafe.t.sol -vvvv
```

## PoC 4: Flash Loan + Oracle Manipulation

### Idea en lenguaje humano

Si un lending usa precio spot de un AMM como oracle, un atacante puede pedir un flash loan, mover el precio en el mismo bloque y pedir prestado de más contra colateral sobrevaluado.

### Contratos

- `src/exploits/FlashLoanOracle/MockERC20.sol`: tokens mock (colateral + stable).
- `src/exploits/FlashLoanOracle/SimpleAMM.sol`: AMM simple con precio spot manipulable.
- `src/exploits/FlashLoanOracle/SimpleFlashLender.sol`: proveedor de flash loan.
- `src/exploits/FlashLoanOracle/VulnerableLending.sol`: lending vulnerable que confía en spot price.
- `src/exploits/FlashLoanOracle/SafeLending.sol`: lending mitigado con precio de referencia + guard de desviación.
- `src/exploits/FlashLoanOracle/FlashLoanPriceAttack.sol`: contrato atacante.

### Qué muestra el test

- En vulnerable: el atacante usa flash loan, manipula precio spot y extrae liquidez del lending.
- En seguro: la operación se bloquea por desviación excesiva entre spot y oracle.

### Comando

```bash
forge test --match-path test/exploits/FlashLoanOracleManipulation.t.sol -vvvv
```

### Hallazgo de Riesgo (par anonimizado)

Escaneo defensivo sobre pools V3 del par `F/////X/USDCe` (fees `500`, `3000`, `10000`) en Arbitrum:

- `activeLiquidity = 0` en las 3 pools
- `observationCardinality = 1` en las 3 pools
- Alertas del scanner: cardinalidad baja y liquidez activa muy baja

Interpretacion tecnica:

1. Con liquidez activa nula, el precio spot no es una referencia robusta para decisiones de riesgo.
2. Con cardinalidad `1`, la capacidad de construir TWAP confiable es practicamente inexistente.
3. Un protocolo que dependa de spot price en estas condiciones aumenta de forma material su superficie de manipulacion economica.

Recomendacion:

- No usar spot directo como oracle para lending/collateral.
- Exigir fuentes robustas (TWAP con ventana suficiente y/o oracle externo) mas guardas de desviacion y circuit breakers.

### Contraste de Calidad de Pool (defensivo)

Caso robusto observado (Arbitrum, pool activa):

- `token0`: WETH
- `token1`: ARB
- `fee`: `500`
- `activeLiquidity`: `933388555057108792957606`
- `observationCardinality`: `3600`
- `observationCardinalityNext`: `3600`
- Sin alertas del scanner

Conclusion defensiva:

1. Una pool con liquidez activa alta y cardinalidad amplia ofrece una base de precio mas estable.
2. Una pool con liquidez nula y cardinalidad minima no debe usarse como fuente de precio para decisiones sensibles.
3. La seguridad de pricing depende de la calidad de la fuente y de guardas adicionales (TWAP robusto, desviacion maxima, circuit breakers).
