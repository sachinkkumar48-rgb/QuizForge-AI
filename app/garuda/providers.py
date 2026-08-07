"""
GARUDA AI Provider Framework.

Defines the abstract BaseAIProvider, AIProviderRegistry, and AIProviderFactory.
Follows Clean Architecture, Strategy Pattern, Factory Pattern, and Open/Closed Principle.

Does NOT depend on FastAPI, Flutter, SQLAlchemy, HTTP, or concrete AI SDKs.
"""
from abc import ABC, abstractmethod
from typing import AsyncGenerator, Dict, List, Optional, Type, Set

from app.garuda.domain import ProviderUnavailableException
from app.garuda.interfaces import IAIServiceProvider


class BaseAIProvider(IAIServiceProvider, ABC):
    """
    Abstract base class for all GARUDA AI providers (Gemini, Claude, OpenAI, Ollama, Local).
    Implements the IAIServiceProvider interface contract.
    """

    def __init__(self, config: Optional[Dict] = None):
        self.config = config or {}

    @property
    @abstractmethod
    def name(self) -> str:
        """Returns the unique identifier name of the AI provider."""
        pass

    @property
    def capabilities(self) -> Set[str]:
        """
        Returns set of supported capabilities.
        Example capabilities: {'text_generation', 'streaming', 'embedding', 'vision'}
        """
        return {"text_generation", "streaming"}

    def get_provider_name(self) -> str:
        return self.name

    @abstractmethod
    async def generate_response(self, prompt: str, context: Optional[str] = None) -> str:
        """Generates a complete text response for a given prompt and context."""
        pass

    @abstractmethod
    async def stream_response(self, prompt: str, context: Optional[str] = None) -> AsyncGenerator[str, None]:
        """Streams text token chunks for a given prompt and context."""
        pass

    def count_tokens(self, text: str) -> int:
        """Estimates token count for a text string (default rough heuristic)."""
        if not text:
            return 0
        return len(text.split())

    async def is_healthy(self) -> bool:
        """Checks provider health/reachability."""
        return True


class AIProviderRegistry:
    """
    Registry for managing AI provider classes and active instances.
    Provides open extension mechanism for registering new providers.
    """

    _registry: Dict[str, Type[BaseAIProvider]] = {}
    _default_provider_name: Optional[str] = None

    @classmethod
    def register(cls, name: str, provider_cls: Type[BaseAIProvider], set_as_default: bool = False) -> None:
        """Registers a concrete provider class under a name key."""
        clean_name = name.lower().strip()
        cls._registry[clean_name] = provider_cls
        if set_as_default or cls._default_provider_name is None:
            cls._default_provider_name = clean_name

    @classmethod
    def get_provider_cls(cls, name: str) -> Type[BaseAIProvider]:
        """Retrieves a registered provider class by name."""
        clean_name = name.lower().strip()
        if clean_name not in cls._registry:
            raise ProviderUnavailableException(
                clean_name, f"Provider '{clean_name}' is not registered in AIProviderRegistry."
            )
        return cls._registry[clean_name]

    @classmethod
    def list_providers(cls) -> List[str]:
        """Returns list of registered provider names."""
        return list(cls._registry.keys())

    @classmethod
    def set_default(cls, name: str) -> None:
        """Sets default provider name."""
        clean_name = name.lower().strip()
        if clean_name not in cls._registry:
            raise ProviderUnavailableException(
                clean_name, f"Cannot set unregistered provider '{clean_name}' as default."
            )
        cls._default_provider_name = clean_name

    @classmethod
    def get_default_name(cls) -> Optional[str]:
        """Returns default provider name."""
        return cls._default_provider_name

    @classmethod
    def clear(cls) -> None:
        """Clears the registry (useful for testing)."""
        cls._registry.clear()
        cls._default_provider_name = None


class AIProviderFactory:
    """
    Factory for instantiating AI Providers using Strategy & Factory patterns.
    Enables dynamic provider creation and automatic fallback cascades.
    """

    @staticmethod
    def create(provider_name: Optional[str] = None, config: Optional[Dict] = None) -> BaseAIProvider:
        """
        Creates an instance of the requested AI Provider.
        If provider_name is None, uses default registered provider.
        """
        target_name = provider_name or AIProviderRegistry.get_default_name()
        if not target_name:
            raise ProviderUnavailableException(
                "DEFAULT", "No AI providers are registered in AIProviderRegistry."
            )

        provider_cls = AIProviderRegistry.get_provider_cls(target_name)
        return provider_cls(config=config)

    @staticmethod
    def create_with_fallback(
        primary_name: str, fallback_names: List[str], config: Optional[Dict] = None
    ) -> BaseAIProvider:
        """
        Attempts to create primary provider, falling back to registered alternatives if unavailable.
        """
        candidates = [primary_name] + fallback_names
        for name in candidates:
            try:
                return AIProviderFactory.create(name, config=config)
            except ProviderUnavailableException:
                continue

        raise ProviderUnavailableException(
            primary_name, f"None of the candidate providers ({candidates}) are registered."
        )
