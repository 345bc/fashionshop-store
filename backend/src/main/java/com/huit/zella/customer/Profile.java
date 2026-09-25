package com.huit.zella.customer;

import java.io.Serializable;
import java.util.List;

public record Profile(Long id, String email, String username, List<String> roles) implements Serializable {
}
