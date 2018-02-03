import importlib

from xld.kubernetes.resource.factory import K8SResourceFactory


class OpenShiftResourceFactory(K8SResourceFactory):
    def __init__(self, deployed):
        super(OpenShiftResourceFactory, self).__init__(deployed)
        self.__deployed = deployed

    def is_supported(self, data):
        unsupported_resources = filter(lambda item: item not in self._get_supported_resources(),
                                       map(lambda item: item['kind'], data['items'])) if \
            data['kind'] == 'List' else (
            [data['kind']] if data['kind'] not in self._get_supported_resources() else None)
        return self._is_valid_resource_type(data), unsupported_resources

    def get(self, data):
        return self._resolve(data)

    @staticmethod
    def get_resource_order():
        resource_order = {
            'Route': {'Create': 75,'Modify': 60,'Destroy': 50},
            'ImageStream': {'Create': 75,'Modify': 60,'Destroy': 50},
            'BuildConfig': {'Create': 75,'Modify': 60,'Destroy': 50},
            'DeploymentConfig': {'Create': 70,'Modify': 54,'Destroy': 43}
        }

        resource_order.update(K8SResourceFactory.get_resource_order())
        return resource_order

    @staticmethod
    def get_resource_wait_details():
        return {
            "Create": {
                    "Default": {'script': 'create_update_wait', 'action': "created"},
                    "Pod": {'script': 'create_update_wait', 'action': "in running state"},
                    "Deployment": {'script': 'deployment/create_update_wait', 'action': "in running state"}
            },
            "Destroy": {
                    "Default": {'script': 'delete_wait', 'action': "destroyed completely"}
            },
            "Modify": {
                    "Default": {'script': 'create_update_wait', 'action': "modified"},
                    "Pod": {'script': 'create_update_wait', 'action': "in running state"},
                    "Deployment": {'script': 'deployment/create_update_wait', 'action': "in running state"}
            }
        }

    def _resolve(self, data):
        try:
            clazz = "{0}ResourceProvider".format(data["kind"])
            factory_module = importlib.import_module("xld.openshift.resource_provider")
            provider_clazz = getattr(factory_module, clazz)
            instance = provider_clazz(self.__deployed.container)
            return instance
        except:
            return super(OpenShiftResourceFactory, self)._resolve(data)

    def _is_valid_resource_type(self, data):
        supported_resource_types = self._get_supported_resources()
        return reduce(lambda acc, cur: bool(acc and (cur in supported_resource_types)),
                      map(lambda item: item['kind'], data['items'])) \
            if data['kind'] == 'List' else  data['kind'] in supported_resource_types

    @staticmethod
    def _get_supported_resources():
        return OpenShiftResourceFactory.get_resource_order().keys()
