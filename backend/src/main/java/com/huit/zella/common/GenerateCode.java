package com.huit.zella.common;

import java.util.Random;
import java.util.concurrent.ThreadLocalRandom;

public class GenerateCode {
    public static String generate(String code) {
        int number = ThreadLocalRandom.current().nextInt(1000, 10000);
        return code + number;
    }
}
