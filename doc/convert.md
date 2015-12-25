# Data conversion

V8 has a set of classes for JavaScript types - `Object`, `Array`, `Number`, etc.
There is a `v8pp::convert` template to convert fundamental and user-defined C++ types
from and to V8 JavaScript types in a header file [`v8pp/convert.hpp`](../v8pp/convert.hpp)

Function template `v8pp::to_v8(v8::Isolate*, T const& value)` converts a C++ value to
a V8 Value instance:

```c++
v8::Isolate* isolate; // some V8 isolate

v8::Local<v8::Value>  v8_int = v8pp::to_v8(isolate, 42);
v8::Local<v8::String> v8_str = v8pp::to_v8(isolate, "hello");
```

The oppisite function  template `v8pp::from_v8<T>(v8::Isolate*, v8::Handle<v8::Value> value)`
converts a V8 value to C++ value of explicitlty delcared type `T`:

```c++
auto i = v8pp::from_v8<int>(isolate, v8_int); // i == 42
auto s = v8pp::from_v8<std::string>(isolate, v8_str); // s = "hello"
```

And there is a `v8pp::from_v8<T>(v8::Isolate*, v8::Handle<v8::Value>, T const& default_value)`
overloading to convert a V8 value or to return `default_value` on conversion error:

```c++
auto i2 = v8pp::from_v8<int>(isolate, v8_str, -1); // i2 == -1 
```

Currently v8pp allows following conversions:

  * `bool` <-> `v8::Boolean`
  * integral (`short`, `int`, `long`, and similar) <-> `v8::Number`
  * C++ `enum` <--> `v8::Number`
  * floating point (`float`, `double`) <-> `v8::Number`
  * `std::vector<T>` <-> `v8::Array`
  * `std::map<Key, Value>` <-> `v8::Object`
  * wrapped C++ objects <-> `v8::Object`

**Caution:** JavaScript has no distinct integer an floating types.
It is unsafe to convert integer values greater than 2^53


## Strings

Allowed conversions for UTF-8 encoded `std::string`, UTF-16 encoded `std::wstring`,
zero-terminated C strings with optional explicit length supplied:

```c++
v8::Isolate* isolate;

v8::Local<v8::String> v8_str1 = v8pp::to_v8(isolate, std::string(UTF-8 encoded std::string");
v8::Local<v8::String> v8_str2 = v8pp::to_v8(isolate, "UTF-8 encoded C-string");
v8::Local<v8::String> v8_str3 = v8pp::to_v8(isolate, L"UTF-16 encoded string with optional explicit length", 21);

auto const str1 = v8pp::from_v8<std::string>(isolate, v8_str1);
auto const str2 = v8pp::from_v8<char const*>(isolate, v8_str2); // really a `std::string const&` like instance
auto const str3 = v8pp::from_v8<std::wstring>(isolate, v8_str3);
```


## Arrays and Objects

There is a `v8pp::to_v8(v8::Isolate*, InputIterator begin, InputIterator end)`
overloading to convert a pair of input iterators to V8 Array:

```c++
v8::Local<v8::Array> arr = v8pp::to_v8(isolate, std::list<std::string>{ "a", "b", "c" });
```

Default conversion for `std::vector<T>` is `v8::Array` if conversion for type `T` is allowed.

For `std::map<Key, Type>` is `v8::Object` if conversion for types `Key` and `Value` are allowed.


## Wrapped C++ objects

Wrapped C++ objects can be converted by pointer or by reference:

```c++
v8::Local<v8::Object> obj = v8::class_<MyClass>::create_object(isolate);

MyClass* ptr = v8pp::from_v8<MyClass*>(isolate, obj);
MyClass& ref = v8pp::from_v8<MyClass&>(isolate, obj);

MyClass* empty = v8pp::from_v8<MyClass*>(isolate, v8::Null()); // empty == nullptr
MyClass& err = v8pp::from_v8<MyClass&>(isolate, v8::Null()); // throws std::runtime_error("expected C++ wrapped object")

v8::Local<v8::Object> obj2 = v8pp::to_v8(isolate, ptr); // obj == obj2
v8::Local<v8::Object> obj3 = v8pp::to_v8(isolate, ref); // obj == obj3

// convert to V8 unwrapped C++ object returns empty handle
v8::Local<v8::Object> obj4 = v8pp::to_v8(isolate, new MyClass{}); // obj4.IsEmpty() == true
```


## User-defined types

A `v8pp::convert` template should be specialized to allow conversion from/to V8 values
for user defined type that is has not been wrapped with `v8pp::class_`

Generic `v8pp::convert` template have such an interface:

```c++
// Generic convertor
template<typename T>
struct convert
{
    // C++ return type for v8pp::from_v8() function
	using from_type = T;

	// V8 return type for v8pp::to_v8() function
	using to_type = v8::Handle<v8::Value>;

	// Is V8 value valid to convert from?
	static bool is_valid(v8::Isolate* isolate, v8::Handle<v8::Value> value);

	// Convert V8 value to C++ 
	static from_type from_v8(v8::Isolate* isolate, v8::Handle<v8::Value> value);

	// Convert C++ value to V8
	static to_type to_v8(v8::Isolate* isolate, T const& value);
};
```

Example for a user type:

```c++
struct Vector3
{
	float x, y, x;
};

namespace v8pp {

template<>
struct convert<Vector3>
{
	using from_type = Vector3;
	using to_type = v8::Handle<v8::Array>;

	static bool is_valid(v8::Isolate*, v8::Handle<v8::Value> value)
	{
		return !value.IsEmpty() && value->IsArray() && value->Length() == 3;
	}

	static form_type from_v8(v8::Isolate* isolate, v8::Handle<v8::Value> value)
	{
		if (!is_valid(isolate, value))
		{
			throw std::invalid_argument("expected [x, y, z] array");
		}

		v8::HandleScope scope(isolate);
		v8::Local<v8::Array> arr = value.As<v8::Array>();

		from_type result;
		result.x = v8pp::from_v8<float>(isolate, arr->Get(0));
		result.y = v8pp::from_v8<float>(isolate, arr->Get(1));
		result.z = v8pp::from_v8<float>(isolate, arr->Get(2));

		return result;
	}

	static to_type to_v8(v8::Isolate* isolate, Vector3 const& value)
	{
		v8::EscapableHandleScope scope(isolate);

		v8::Local<v8::Arrya> arr = v8::Array::New(isolate, 3);
		arr->Set(0, v8pp::to_v8(isolate, value.x));
		arr->Set(1, v8pp::to_v8(isolate, value.y));
		arr->Set(2, v8pp::to_v8(isolate, value.z));

		return scope.Escape(arr);
	}
};

} // v8pp
```

User defined class template should also specialize `v8pp::is_wrapped_class` as `std::false_type`
in order to disable conversion as a C++ wrapped with `v8pp::class_` type:

```c++
template<typename T>
struct Vector3
{
	T x, y, x;
};

namespace v8pp {

template<typename T>
struct convert<Vector3<T>>
{
	using from_type = Vector3<T>;
	using to_type = v8::Handle<v8::Array>;

	static bool is_valid(v8::Isolate*, v8::Handle<v8::Value> value)
	{
		return !value.IsEmpty() && value->IsArray() && value->Length() == 3;
	}

	static form_type from_v8(v8::Isolate* isolate, v8::Handle<v8::Value> value)
	{
		if (!is_valid(isolate, value))
		{
			throw std::invalid_argument("expected [x, y, z] array");
		}

		v8::HandleScope scope(isolate);
		v8::Local<v8::Array> arr = value.As<v8::Array>();

		from_type result;
		result.x = v8pp::from_v8<T>(isolate, arr->Get(0));
		result.y = v8pp::from_v8<T>(isolate, arr->Get(1));
		result.z = v8pp::from_v8<T>(isolate, arr->Get(2));

		return result;
	}

	static to_type to_v8(v8::Isolate* isolate, Vector3<T> const& value)
	{
		v8::EscapableHandleScope scope(isolate);

		v8::Local<v8::Arrya> arr = v8::Array::New(isolate, 3);
		arr->Set(0, v8pp::to_v8(isolate, value.x));
		arr->Set(1, v8pp::to_v8(isolate, value.y));
		arr->Set(2, v8pp::to_v8(isolate, value.z));

		return scope.Escape(arr);
	}
};

template<typename T>
struct is_wrapped_class<Vector3<T>> : std::false_type {};

} // v8pp
```
