package com.gamgam.backend.place;
import com.sun.net.httpserver.HttpServer;
import com.gamgam.backend.global.exception.*;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;

class ExternalPlaceClientTests {
    HttpServer server;
    String base;
    AtomicReference<String> authorization=new AtomicReference<>(),query=new AtomicReference<>();
    @BeforeEach void start() throws Exception {
        server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        base="http://127.0.0.1:"+server.getAddress().getPort();
    }
    @AfterEach void stop() {server.stop(0);}
    void respond(String body,int status) {
        server.createContext("/v2/local/search/",exchange->{
            authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));query.set(exchange.getRequestURI().getRawQuery());
            byte[] bytes=body.getBytes(StandardCharsets.UTF_8);exchange.sendResponseHeaders(status,bytes.length);
            try(var out=exchange.getResponseBody()){out.write(bytes);}
        });server.start();
    }
    @Test void mapsCoordinatesPaginationAndAuthorization() {
        respond("""
            {"meta":{"is_end":false},"documents":[{"id":"123","place_name":"Cafe","x":"127.1","y":"37.2",
            "address_name":"Old address","road_address_name":"Road address","category_name":"Food","place_url":"https://place.map.kakao.com/123"}]}
            """,200);
        var result=new ExternalPlaceClient("test-key",base).search("Cafe & tea",false,37.0,127.0,2,5);
        assertThat(authorization.get()).isEqualTo("KakaoAK test-key");
        assertThat(query.get()).contains("query=Cafe+%26+tea","page=2","size=5","y=37.0","x=127.0");
        assertThat(result.hasNext()).isTrue();
        assertThat(result.items().getFirst().latitude()).isEqualTo(37.2);
        assertThat(result.items().getFirst().longitude()).isEqualTo(127.1);
        assertThat(result.items().getFirst().address()).isEqualTo("Road address");
    }
    @Test void addressSearchHandlesMissingRoadAddress() {
        respond("{\"meta\":{\"is_end\":true},\"documents\":[{\"address_name\":\"Street\",\"x\":\"127\",\"y\":\"37\",\"road_address\":null}]}",200);
        var result=new ExternalPlaceClient("test",base).search("Street",true,null,null,1,15);
        assertThat(result.items().getFirst().name()).isEqualTo("Street");assertThat(result.hasNext()).isFalse();
    }
    @Test void upstreamFailuresDoNotLeakProviderBody() {
        respond("private upstream error",429);
        assertThatThrownBy(()->new ExternalPlaceClient("secret",base).search("Cafe",false,null,null,1,15))
                .isInstanceOfSatisfying(BusinessException.class,e->assertThat(e.errorCode()).isEqualTo(ErrorCode.PROVIDER_UNAVAILABLE));
    }
    @Test void unconfiguredProviderFailsExplicitlyWithoutNetwork() {
        assertThatThrownBy(()->new ExternalPlaceClient("",base).search("Cafe",false,null,null,1,15))
                .isInstanceOf(BusinessException.class);
    }
}
