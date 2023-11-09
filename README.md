[![tests](https://github.com/jonatandahora/challenge_backend/actions/workflows/elixir.yaml/badge.svg)](https://github.com/jonatandahora/challenge_backend/actions/workflows/elixir.yaml)

# Desafio Cumbuca Backend

Esse app foi desenvolvido para o _desafio backend da Cumbuca_

O mesmo se encontra deployado em [https://challenge-backend.fly.dev/](https://challenge-backend.fly.dev/)

Também disponibilizo uma collection do insomnia para testes já com os ambientes e headers configurados [aqui](challenge-insomnia.json)

## Endpoints

#### Criar conta de usúario

<details>
 <summary><code>POST</code> <code><b>/</b></code> <code>accounts</code></summary>


##### Parâmetros

> | nome         | tipo        | tipo de dado | descrição                |
> | ------------ | ----------- | ------------ | ------------------------ |
> | `first_name` | obrigatório | string       | Primeiro nome do usuário |
> | `last_name` | obrigatório | string       | sobrenome do usuário |
> | `cpf` | obrigatório | string       | CPF sem formatação |
> | `pasword` | obrigatório | string       | senha de acesso |
> | `balance` | obrigatório | string       | saldo inicial do usuário |
</details>

---


#### Login

<details>
 <summary><code>POST</code> <code><b>/</b></code> <code>accounts</code> <code><b>/</b></code> <code>login</code> </summary>

##### Parâmetros

> | nome         | tipo        | tipo de dado | descrição                |
> | ------------ | ----------- | ------------ | ------------------------ |
> | `cpf` | obrigatório | string       | CPF sem formatação |
> | `pasword` | obrigatório | string       | senha de acesso |

Após um login bem sucedido, todas as operaçoes subsequentes precisar incluir o Header `Authorization` com o token e o prefixo `Bearer`
</details>

---

#### Consultar Saldo

<details>
 <summary><code>GET</code> <code><b>/</b></code> <code>accounts</code> <code><b>/</b></code> <code>balance</code> </summary>

>


Retorna o saldo atual da conta logada atraves do Header `Authorization`
</details>

---

#### Criar Transação

<details>
 <summary><code>POST</code> <code><b>/</b></code> <code>transactions</code> </summary>

>
##### Parâmetros

> | nome         | tipo        | tipo de dado | descrição                |
> | ------------ | ----------- | ------------ | ------------------------ |
> | `receiver_id` | obrigatório | UUID       | Identificador da conta recebedora |
> | `amount` | obrigatório | integer       | Valor da transação em centavos |
> | `idempotency_key` | obrigatório | string       | Identificador único da transação |

A conta pagadora sempre será a do usuário logado, o mesmo não podendo fazer uma transação para sí próprio
</details>

---


#### Estornar Transação

<details>
 <summary><code>PATCH</code> <code><b>/</b></code> <code>transactions</code> <code><b>/</b></code> <code>:identifier</code> <code><b>/</b></code> <code>reverse</code> </summary>

>
##### Parâmetros

> | nome         | tipo        | tipo de dado | descrição                |
> | ------------ | ----------- | ------------ | ------------------------ |
> | `transaction_id` | obrigatório | UUID(URL param)      | Identificador da transação |

A transação só poderá ser estornada caso a conta recebedora original tenha saldo suficiente.
</details>

---

#### Listar Transações Por Data

<details>
 <summary><code>GET</code> <code><b>/</b></code> <code>transactions</code> <code><b>?</b></code> <code>from=</code> <code><b>&</b></code> <code>to=</code> </summary>

>
##### Parâmetros

> | nome         | tipo        | tipo de dado | descrição                |
> | ------------ | ----------- | ------------ | ------------------------ |
> | `from` | obrigatório | Data ISO 8601(Query String)      | Data inicial |
> | `to` | obrigatório | Data ISO 8601(Query String)      | Data final |

Somente serão listadas as transações da conta logada com um range de datas válido
</details>

---
