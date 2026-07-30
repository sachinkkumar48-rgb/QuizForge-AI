"""
Exception types for Identity module.
"""


class IdentityException(Exception):
    """Base exception for Identity module."""

    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class UserAlreadyExistsException(IdentityException):
    def __init__(self, message: str = "User with this email already exists."):
        super().__init__(message, status_code=400)


class InvalidCredentialsException(IdentityException):
    def __init__(self, message: str = "Invalid email or password."):
        super().__init__(message, status_code=401)


class InvalidTokenException(IdentityException):
    def __init__(self, message: str = "Invalid or expired token."):
        super().__init__(message, status_code=401)
