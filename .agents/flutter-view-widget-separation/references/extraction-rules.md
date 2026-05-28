# Regras de extracao

## Manter na view

- `Scaffold`
- `SafeArea`
- `CustomScrollView`, `NestedScrollView` ou scroll principal
- composicao macro da pagina
- wiring com `controller`, `binding`, `route args` ou `GetView`

## Extrair como widget privado no mesmo arquivo

- secoes exclusivas da tela
- cards especificos da home
- tiles e itens de lista locais
- chips, filtros e pequenos agrupamentos visuais
- estados vazios e de erro locais da pagina

## Extrair para arquivo proprio

- widgets reutilizados em mais de uma tela
- componentes com API visual clara
- blocos longos o suficiente para poluir a leitura da tela
- widgets que merecem teste visual isolado

## O que nao fazer

- mover regra de negocio para widget visual
- passar controller inteiro sem necessidade quando poucos campos bastam
- criar dezenas de arquivos para widgets minimos sem reuso
- esconder a estrutura da tela em extracoes excessivas
