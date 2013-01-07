Exemplo 1

Nota: Exemplo básico de adição de um componente primitivo e externalização de uma faceta. Em seguida, é feita uma chamada a faceta externalizada.


1 - Criação de um componente primitivo e um composto.

lua basic_component_server.lua
lua composite_component_server.lua

2 - Execução do cliente 

lua client.lua  


Exemplo 2

Nota: Exemplo básico de uso de um conector. É criado um componente do tipo conector, um componente primitivo e um componente composto. A idéia é externalizar
uma faceta de um subcomponente através de um conector que será responsável pela política de redirecionamento.

1 - Criação de um componente primitivo 

Este componente é o mesmo do Exemplo 1 que implementa a faceta com a interface IHello

2 - Criação de um componente do tipo conector

Este componente deve implementar a mesma faceta do subcomponente, no corpo de cada método da interface devem ser implementadas as políticas de comunicação 
do componente composto e do subcomponente.

3 - Criação do componente composto.


4 - Como executar

lua basic_component_server.lua
lua connector_component.lua
lua composite_component_server.lua
lua testing_connector.lua